import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { Patient } from './patient.entity.js';
import { Appointment } from './appointment.entity.js';
import { CreateAppointmentDto } from './appointment.dto.js';
import { RescheduleAppointmentDto } from './appointment.dto.js';

@Injectable()
export class PatientService {
  constructor(
    @InjectRepository(Patient) private readonly patients: Repository<Patient>,
    @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>,
  ) {}

  async getProfile(id: number) {
    const patient = await this.patients.findOneBy({ id });
    if (!patient) throw new NotFoundException();
    return { ...patient, insurance: null };
  }

  async updateProfile(id: number, changes: Partial<Patient>) {
    const patient = await this.patients.findOneBy({ id });
    if (!patient) throw new NotFoundException();
    Object.assign(patient, changes);
    return this.patients.save(patient);
  }

  createAppointment(patientId: number, input: CreateAppointmentDto) {
    const appointment = this.appointments.create({
      apTime: new Date(input.apTime),
      confirmDate: null,
      address: input.address,
      note: input.note ?? null,
      doctorNote: null,
      confirmCondition: 1,
      cancelReason: null,
      canceledBy: null,
      rescheduled: false,
      doctorName: '',
      patientId,
      doctorId: input.doctorId,
    });
    return this.appointments.save(appointment).catch((error: unknown) => {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { driverError?: { code?: string } }).driverError?.code === '23505') {
        throw new ConflictException('Khung giờ đã được đặt');
      }
      throw error;
    });
  }

  listAppointments(patientId: number) {
    return this.appointments.find({ where: { patientId }, order: { apTime: 'ASC' } });
  }

  async getAppointment(patientId: number, id: number) {
    const appointment = await this.appointments.findOneBy({ id });
    if (!appointment) throw new NotFoundException();
    if (appointment.patientId !== patientId) throw new ForbiddenException();
    return appointment;
  }

  async cancelAppointment(patientId: number, id: number, reason: string) {
    const appointment = await this.getAppointment(patientId, id);
    if (appointment.confirmCondition === 2) throw new ConflictException('Lịch đã khám xong');
    appointment.cancelReason = reason;
    appointment.canceledBy = 'patient';
    return this.appointments.save(appointment);
  }

  async rescheduleAppointment(patientId: number, id: number, changes: RescheduleAppointmentDto) {
    const appointment = await this.getAppointment(patientId, id);
    if (appointment.rescheduled || appointment.cancelReason || appointment.confirmCondition === 2) {
      throw new ConflictException('Lịch không thể đổi thêm');
    }
    const available = await this.appointments.manager.query(
      `SELECT 1 FROM "shiftAssignment" s WHERE s."doctorId" = $1 AND s."status" = 'ACTIVE'
       AND s."startTime" <= $2 AND s."endTime" >= $2::timestamp + interval '30 minutes'
       AND NOT EXISTS (SELECT 1 FROM "appointment" a WHERE a."doctorId" = $1 AND a."apTime" = $2
       AND a."cancelReason" IS NULL AND a."id" <> $3) LIMIT 1`,
      [appointment.doctorId, changes.apTime, id],
    );
    if (!available.length) throw new ConflictException('Khung giờ không còn trống');
    appointment.apTime = new Date(changes.apTime);
    appointment.rescheduled = true;
    if (changes.note !== undefined) appointment.note = changes.note;
    if (appointment.confirmCondition === 0) appointment.confirmCondition = 1;
    return this.appointments.save(appointment);
  }
}
