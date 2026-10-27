import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { Notification } from './notification.entity.js';
import { PaymentController } from './payment.controller.js';
import { PaymentService } from './payment.service.js';
import { PaymentTransaction } from './payment-transaction.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment, Notification, PaymentTransaction])],
  controllers: [PaymentController],
  providers: [PaymentService],
})
export class PaymentModule {}
