import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import type { Relation } from 'typeorm';
import { Appointment } from './appointment.entity.js';

@Entity('appointment_item')
export class AppointmentItem {
  @PrimaryGeneratedColumn() id: number;
  @Column({ length: 200 }) name: string;
  @Column({ type: 'int' }) price: number;
  @Column({ default: true }) bhytCovered: boolean;
  @Column() appointmentId: number;
  @ManyToOne(() => Appointment, (appointment) => appointment.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'appointmentId' }) appointment: Relation<Appointment>;
}
