import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { MedicalReport } from '../patient/medical-report.entity.js';
import { AiController } from './ai.controller.js';
import { AiService } from './ai.service.js';

@Module({ imports: [TypeOrmModule.forFeature([Appointment, MedicalReport])], controllers: [AiController], providers: [AiService] })
export class AiModule {}
