import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { Doctor } from './doctor.entity.js';
import { DoctorController } from './doctor.controller.js';
import { DoctorService } from './doctor.service.js';
import { ShiftAssignment } from './shift-assignment.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Doctor, Appointment, ShiftAssignment])],
  controllers: [DoctorController],
  providers: [DoctorService],
})
export class DoctorModule {}
