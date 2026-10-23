import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from './appointment.entity.js';
import { Patient } from './patient.entity.js';
import { PatientController } from './patient.controller.js';
import { PatientService } from './patient.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment, Patient])],
  controllers: [PatientController],
  providers: [PatientService],
})
export class PatientModule {}
