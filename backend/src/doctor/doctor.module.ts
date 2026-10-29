import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { Doctor } from './doctor.entity.js';
import { DoctorController } from './doctor.controller.js';
import { DoctorService } from './doctor.service.js';
import { ShiftAssignment } from './shift-assignment.entity.js';
import { Shift } from './shift.entity.js';
import { Disease } from '../disease/disease.entity.js';
import { AppointmentItem } from '../patient/appointment-item.entity.js';
import { Account } from '../auth/account.entity.js';
import { AdminController } from './admin.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([Doctor, Appointment, AppointmentItem, Disease, ShiftAssignment, Shift, Account])],
  controllers: [DoctorController, AdminController],
  providers: [DoctorService],
})
export class DoctorModule {}
