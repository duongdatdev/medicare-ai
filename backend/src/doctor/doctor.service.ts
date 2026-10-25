import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { Doctor } from './doctor.entity.js';
import { ShiftAssignment } from './shift-assignment.entity.js';
import { Shift } from './shift.entity.js';
import { BadRequestException } from '@nestjs/common';
import { Disease } from '../disease/disease.entity.js';
import { AppointmentItem } from '../patient/appointment-item.entity.js';
import { calcBill } from '../billing/billing.util.js';
import { CompleteAppointmentDto } from './doctor.dto.js';

@Injectable()
export class DoctorService {
  constructor(
    @InjectRepository(Doctor) private readonly doctors: Repository<Doctor>,
    @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>,
    @InjectRepository(ShiftAssignment) private readonly assignments: Repository<ShiftAssignment>,
    @InjectRepository(Shift) private readonly shifts: Repository<Shift>,
    @InjectRepository(Disease) private readonly diseases: Repository<Disease>,
  ) {}

  list() {
    return this.doctors.find({ order: { name: 'ASC' } });
  }

  shiftTemplates() {
    return this.shifts.find({ order: { startTime: 'ASC' } });
  }

  async registerShift(doctorId: number, shiftId: number, date: string) {
    const shift = await this.shifts.findOneBy({ id: shiftId });
    if (!shift) throw new NotFoundException('Không tìm thấy ca trực');
    const shiftDate = new Date(`${date}T00:00:00+07:00`);
    if (!Number.isFinite(shiftDate.getTime()) || shiftDate <= new Date()) {
      throw new BadRequestException('Ngày đăng ký phải ở tương lai');
    }
    const startTime = new Date(`${date}T${shift.startTime}+07:00`);
    const endTime = new Date(`${date}T${shift.endTime}+07:00`);
    const duplicate = await this.assignments.findOneBy({ doctorId, shiftId, startTime });
    if (duplicate) throw new ConflictException('Ca trực đã đăng ký');
    const assigned = await this.assignments.count({ where: { shiftId, startTime, status: 'ACTIVE' } });
    if (assigned >= 4) throw new ConflictException('Ca trực đã đủ bác sĩ');
    return this.assignments.save(this.assignments.create({
      type: shift.type, startTime, endTime, status: 'ACTIVE', duration: 0, doctorId, shiftId,
    }));
  }

  async listAppointments(doctorId: number, status: number) {
    return this.appointments.find({ where: { doctorId, confirmCondition: status }, order: { apTime: 'ASC' } });
  }

  async confirmAppointment(doctorId: number, appointmentId: number, note?: string) {
    const appointment = await this.appointments.findOneBy({ id: appointmentId });
    if (!appointment) throw new NotFoundException();
    if (appointment.doctorId !== doctorId) throw new ForbiddenException();
    if (appointment.confirmCondition !== 1 || appointment.cancelReason) throw new ConflictException('Lịch không còn chờ xác nhận');
    appointment.confirmCondition = 0;
    appointment.confirmDate = new Date();
    appointment.doctorNote = note ?? null;
    return this.appointments.save(appointment);
  }

  async completeAppointment(doctorId: number, appointmentId: number, input: CompleteAppointmentDto) {
    if (new Set(input.diseaseIds).size !== input.diseaseIds.length) {
      throw new ConflictException('Chẩn đoán bị trùng');
    }
    return this.appointments.manager.transaction(async (manager) => {
      const appointment = await manager.findOne(Appointment, { where: { id: appointmentId }, lock: { mode: 'pessimistic_write' } });
      if (!appointment) throw new NotFoundException();
      if (appointment.doctorId !== doctorId) throw new ForbiddenException();
      if (appointment.confirmCondition !== 0 || appointment.cancelReason) throw new ConflictException('Lịch chưa xác nhận hoặc đã hủy');
      const diseases = await manager.findBy(Disease, { id: In(input.diseaseIds), active: true });
      if (!input.diseaseIds.length || diseases.length !== input.diseaseIds.length) throw new BadRequestException('Danh sách chẩn đoán không hợp lệ');
      const fee = Number(process.env.EXAM_FEE ?? 50000);
      const bill = calcBill(fee, true, diseases.map((disease) => ({ price: disease.price, bhytCovered: disease.bhytCovered })), null, appointment.apTime);
      appointment.confirmCondition = 2;
      appointment.examFee = bill.examFee;
      appointment.examFeeCovered = bill.examFeeCovered;
      appointment.total = bill.total;
      appointment.insuranceRate = bill.insuranceRate;
      appointment.insuranceCovered = bill.insuranceCovered;
      appointment.payable = bill.payable;
      await manager.save(appointment);
      await manager.save(AppointmentItem, diseases.map((disease) => ({
        name: disease.name, price: disease.price, bhytCovered: disease.bhytCovered, appointmentId,
      })));
      return { ...appointment, items: diseases.map(({ name, price, bhytCovered }) => ({ name, price, bhytCovered })), ...bill };
    });
  }

  async availability(doctorId: number, date: string) {
    const start = new Date(`${date}T00:00:00+07:00`);
    const end = new Date(start.getTime() + 86400000);
    const booked = await this.appointments.find({
      where: { doctorId },
      select: { apTime: true, cancelReason: true },
    });
    const occupied = new Set(
      booked.filter((item) => !item.cancelReason).map((item) => item.apTime.toISOString()),
    );
    const slots: string[] = [];
    const shifts = await this.assignments.find({ where: { doctorId, status: 'ACTIVE' } });
    for (const shift of shifts) {
      const shiftStart = Math.max(start.getTime(), shift.startTime.getTime());
      const shiftEnd = Math.min(end.getTime(), shift.endTime.getTime());
      for (let time = shiftStart; time + 30 * 60000 <= shiftEnd; time += 30 * 60000) {
        const slot = new Date(time);
        if (!occupied.has(slot.toISOString())) slots.push(slot.toISOString());
      }
    }
    return [...new Set(slots)].sort();
  }
}
