import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { Doctor } from './doctor.entity.js';
import { ShiftAssignment } from './shift-assignment.entity.js';

@Injectable()
export class DoctorService {
  constructor(
    @InjectRepository(Doctor) private readonly doctors: Repository<Doctor>,
    @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>,
    @InjectRepository(ShiftAssignment) private readonly assignments: Repository<ShiftAssignment>,
  ) {}

  list() {
    return this.doctors.find({ order: { name: 'ASC' } });
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
