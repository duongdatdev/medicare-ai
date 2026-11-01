import { BadRequestException, ForbiddenException, Injectable, NotFoundException, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { timingSafeEqual } from 'node:crypto';
import { IsNull, Repository } from 'typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { buildVietQr } from '../billing/vietqr.util.js';
import { Notification } from './notification.entity.js';
import { PaymentTransaction } from './payment-transaction.entity.js';
import { PayAppointmentDto, SepayWebhookDto } from './payment.dto.js';

@Injectable()
export class PaymentService {
  constructor(
    @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>,
    @InjectRepository(Notification) private readonly notifications: Repository<Notification>,
    @InjectRepository(PaymentTransaction) private readonly transactions: Repository<PaymentTransaction>,
    private readonly config: ConfigService,
  ) {}

  async pay(patientId: number, appointmentId: number, { method }: PayAppointmentDto) {
    const appointment = await this.appointments.findOneBy({ id: appointmentId });
    if (!appointment) throw new NotFoundException();
    if (appointment.patientId !== patientId) throw new ForbiddenException();
    if (appointment.confirmCondition !== 2 || appointment.payable === null) throw new BadRequestException('Lịch chưa có hóa đơn');
    if (appointment.paymentStatus === 'paid' || appointment.paymentStatus === 'pending') throw new BadRequestException('Lịch không thể thanh toán lại');
    if (appointment.payable <= 0) throw new BadRequestException('Không cần thanh toán');
    let qr: object | undefined;
    if (method === 'qr') {
      const bin = this.config.get<string>('PAYMENT_BANK_BIN');
      const accountNo = this.config.get<string>('PAYMENT_ACCOUNT_NO');
      if (!bin || !accountNo) throw new ServiceUnavailableException('Chưa cấu hình tài khoản nhận');
      const content = `DACN${appointment.id}`;
      qr = { payload: buildVietQr({ bin, accountNo, amount: appointment.payable, content }), bankName: this.config.get('PAYMENT_BANK_NAME', bin), accountNo, accountName: this.config.get('PAYMENT_ACCOUNT_NAME', ''), amount: appointment.payable, content };
    }
    appointment.paymentMethod = method;
    appointment.paymentStatus = 'pending';
    await this.appointments.save(appointment);
    return { paymentStatus: 'pending', paymentMethod: method, ...(qr ? { qr } : {}) };
  }

  assertWebhookKey(header: string | undefined) {
    const expected = this.config.get<string>('SEPAY_API_KEY');
    if (!expected) throw new ServiceUnavailableException('Webhook chưa cấu hình');
    const supplied = header?.replace(/^Apikey\s+/i, '') ?? '';
    const left = Buffer.from(expected);
    const right = Buffer.from(supplied);
    if (left.length !== right.length || !timingSafeEqual(left, right)) throw new UnauthorizedException();
  }

  async handleWebhook(input: SepayWebhookDto) {
    if (input.transferType !== 'in') return { success: true };
    await this.transactions.manager.transaction(async (manager) => {
      const inserted = await manager.query(
        `INSERT INTO "payment_transaction" ("sepayId", "content", "transferAmount") VALUES ($1, $2, $3) ON CONFLICT ("sepayId") DO NOTHING RETURNING "id"`,
        [String(input.id), input.content, input.transferAmount],
      );
      if (!inserted.length) return;
      const match = input.content.match(/^DACN(\d+)(?:\s|$)/i);
      const appointment = match
        ? await manager.findOne(Appointment, { where: { id: Number(match[1]) }, lock: { mode: 'pessimistic_write' } })
        : null;
      if (appointment && appointment.paymentStatus === 'pending' && appointment.paymentMethod === 'qr' && appointment.payable === input.transferAmount) {
        appointment.paymentStatus = 'paid';
        appointment.paidAt = new Date();
        await manager.save(appointment);
        await manager.save(Notification, manager.create(Notification, {
          title: 'Đã nhận thanh toán',
          body: `Lịch #${appointment.id} đã nhận ${input.transferAmount} VND từ SePay.`,
          appointmentId: appointment.id,
          readAt: null,
        }));
        return;
      }
      await manager.save(Notification, manager.create(Notification, {
        title: 'Giao dịch cần kiểm tra',
        body: `SePay ${input.id}: ${input.transferAmount} VND (${input.content})`,
        appointmentId: appointment?.id ?? null,
        readAt: null,
      }));
    });
    return { success: true };
  }

  payments(status: 'pending' | 'paid') {
    return this.appointments.find({ where: { paymentStatus: status, cancelReason: IsNull() }, relations: { patient: true, doctor: true }, order: status === 'paid' ? { paidAt: 'DESC' } : { apTime: 'DESC' }, take: 100 });
  }

  async confirm(adminId: number, id: number) {
    const appointment = await this.appointments.findOneBy({ id });
    if (!appointment) throw new NotFoundException();
    if (appointment.paymentStatus !== 'pending') throw new BadRequestException('Lịch không chờ xác nhận');
    appointment.paymentStatus = 'paid'; appointment.paidAt = new Date(); appointment.paidBy = adminId;
    await this.appointments.save(appointment);
    return { id, paymentStatus: 'paid' };
  }

  notificationsList() { return this.notifications.find({ order: { createdAt: 'DESC' }, take: 100 }); }
  async unreadCount() { return { count: await this.notifications.countBy({ readAt: IsNull() }) }; }
  async readAll() { await this.notifications.update({ readAt: IsNull() }, { readAt: new Date() }); return { ok: true }; }
}
