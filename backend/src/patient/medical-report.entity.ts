import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Appointment } from './appointment.entity.js';

@Entity('medical_report')
export class MedicalReport {
  @PrimaryGeneratedColumn() id: number;
  @ManyToOne(() => Appointment, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'appointmentId' }) appointment: Appointment;
  @Column({ type: 'bytea' }) pdf: Buffer;
  @CreateDateColumn() createdAt: Date;
}
