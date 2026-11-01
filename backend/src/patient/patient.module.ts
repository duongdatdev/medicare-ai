import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from './appointment.entity.js';
import { Patient } from './patient.entity.js';
import { PatientController } from './patient.controller.js';
import { PatientService } from './patient.service.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment, Patient]), AuthModule],
  controllers: [PatientController],
  providers: [PatientService],
})
export class PatientModule {}
