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
import { CreateDoctorDto, UpdateDoctorDto } from './doctor.dto.js';
import { Account } from '../auth/account.entity.js';
import * as bcrypt from 'bcrypt';
import { Patient } from '../patient/patient.entity.js';
import { MedicalReport } from '../patient/medical-report.entity.js';

@Injectable()
export class DoctorService {
  constructor(
    @InjectRepository(Doctor) private readonly doctors: Repository<Doctor>,
    @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>,
    @InjectRepository(ShiftAssignment) private readonly assignments: Repository<ShiftAssignment>,
    @InjectRepository(Shift) private readonly shifts: Repository<Shift>,
    @InjectRepository(Disease) private readonly diseases: Repository<Disease>,
    @InjectRepository(Account) private readonly accounts: Repository<Account>,
    @InjectRepository(Patient) private readonly patients: Repository<Patient>,
    @InjectRepository(MedicalReport) private readonly reports: Repository<MedicalReport>,
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

  myShifts(doctorId: number) {
    return this.assignments.find({ where: { doctorId }, order: { startTime: 'ASC' } });
  }

  shiftOverview() {
    return this.assignments.find({ where: { status: 'ACTIVE' }, relations: { doctor: true, shift: true }, order: { startTime: 'ASC' } });
  }

  async cancelAssignment(doctorId: number, id: number) {
    const assignment = await this.assignments.findOneBy({ id });
    if (!assignment) throw new NotFoundException();
    if (assignment.doctorId !== doctorId) throw new ForbiddenException();
    if (assignment.status !== 'ACTIVE') throw new ConflictException('Ca trực đã hủy');
    assignment.duration = Math.max(0, Math.min(assignment.endTime.getTime(), Date.now()) - assignment.startTime.getTime()) / 3600000;
    assignment.status = 'CANCELED';
    return this.assignments.save(assignment);
  }

  async deleteAssignment(doctorId: number, id: number) {
    const assignment = await this.assignments.findOneBy({ id });
    if (!assignment) throw new NotFoundException();
    if (assignment.doctorId !== doctorId) throw new ForbiddenException();
    await this.assignments.remove(assignment);
  }

  async cancelShift(doctorId: number, shiftId: number) {
    const assignment = await this.assignments.findOneBy({ doctorId, shiftId, status: 'ACTIVE' });
    if (!assignment) throw new NotFoundException('Không tìm thấy ca trực');
    const stoppedAt = Math.min(Math.max(Date.now(), assignment.startTime.getTime()), assignment.endTime.getTime());
    assignment.duration = Math.round(Math.max(0, stoppedAt - assignment.startTime.getTime()) / 3600000 * 100) / 100;
    assignment.endTime = new Date(stoppedAt);
    assignment.status = 'CANCELED';
    return this.assignments.save(assignment);
  }

  async deleteShift(doctorId: number, shiftId: number) {
    await this.assignments.delete({ doctorId, shiftId });
  }

  async createDoctor(input: CreateDoctorDto) {
    return this.doctors.manager.transaction(async (manager) => {
      if (await manager.exists(Account, { where: { email: input.email } })) throw new ConflictException('Email đã tồn tại');
      const doctor = await manager.save(Doctor, { ...input, dateOfBirth: new Date(input.dateOfBirth), avatar: '' });
      const account = await manager.save(Account, {
        email: input.email, passwordHash: await bcrypt.hash(input.password, 10), role: 'doctor',
        doctorId: doctor.id, patientId: null,
      });
      return { id: account.id, doctorId: doctor.id, email: input.email, role: 'doctor' };
    });
  }

  async getDoctor(id: number) {
    const doctor = await this.doctors.findOneBy({ id });
    if (!doctor) throw new NotFoundException();
    return doctor;
  }

  async updateDoctor(id: number, changes: UpdateDoctorDto) {
    const doctor = await this.getDoctor(id);
    return this.doctors.save(Object.assign(doctor, changes));
  }

  async salaries(hourlyRate = 300000) {
    const assignments = await this.assignments.find();
    const doctors = await this.doctors.find({ order: { name: 'ASC' } });
    return doctors.map((doctor) => {
      const hours = assignments.filter((assignment) => assignment.doctorId === doctor.id)
        .reduce((sum, assignment) => sum + (assignment.status === 'ACTIVE'
          ? (assignment.endTime.getTime() - assignment.startTime.getTime()) / 3600000
          : assignment.duration), 0);
      return { doctorId: doctor.id, doctorName: doctor.name, totalHours: hours, hourlyRate, salary: Math.round(hours * hourlyRate) };
    });
  }

  async listAppointments(doctorId: number, status: number) {
    return this.appointments.find({ where: { doctorId, confirmCondition: status }, order: { apTime: 'ASC' } });
  }

  async getAppointmentDetail(doctorId: number, appointmentId: number) {
    const appointment = await this.appointments.findOne({ where: { id: appointmentId }, relations: { patient: true, items: true } });
    if (!appointment) throw new NotFoundException();
    if (appointment.doctorId !== doctorId) throw new ForbiddenException();
    return appointment;
  }

  async deleteAppointment(doctorId: number, appointmentId: number) {
    await this.getAppointmentDetail(doctorId, appointmentId);
    await this.appointments.delete(appointmentId);
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

  async cancelAppointment(doctorId: number, appointmentId: number, reason: string) {
    const appointment = await this.appointments.findOneBy({ id: appointmentId });
    if (!appointment) throw new NotFoundException();
    if (appointment.doctorId !== doctorId) throw new ForbiddenException();
    if (appointment.confirmCondition === 2 || appointment.cancelReason) throw new ConflictException('Lịch đã kết thúc');
    appointment.cancelReason = reason;
    appointment.canceledBy = 'doctor';
    return this.appointments.save(appointment);
  }

  async rescheduleAppointment(doctorId: number, appointmentId: number, apTime: string) {
    const appointment = await this.appointments.findOneBy({ id: appointmentId });
    if (!appointment) throw new NotFoundException();
    if (appointment.doctorId !== doctorId) throw new ForbiddenException();
    if (appointment.confirmCondition !== 0 || appointment.rescheduled || appointment.cancelReason) throw new ConflictException('Lịch không thể đổi giờ');
    const target = new Date(apTime);
    if (!(await this.availability(doctorId, target.toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }))).includes(target.toISOString())) {
      throw new ConflictException('Khung giờ không còn trống');
    }
    appointment.apTime = target;
    appointment.rescheduled = true;
    return this.appointments.save(appointment);
  }

  async getReport(appointmentId: number) {
    const report = await this.reports.findOne({ where: { appointment: { id: appointmentId } }, order: { createdAt: 'DESC' } });
    return report?.pdf ?? null;
  }

  async reExamination(doctorId: number, patientId: number, apTime: string, address: string, note?: string) {
    const patient = await this.patients.findOneBy({ id: patientId });
    const doctor = await this.doctors.findOneBy({ id: doctorId });
    if (!patient || !doctor) throw new NotFoundException();
    return this.appointments.save(this.appointments.create({
      apTime: new Date(apTime), confirmDate: new Date(), address, note: note ?? null,
      doctorNote: null, confirmCondition: 0, cancelReason: null, canceledBy: null,
      rescheduled: false, doctorName: doctor.name, patientId, doctorId,
    }));
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
