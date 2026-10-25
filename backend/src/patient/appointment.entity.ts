import { Column, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn, JoinColumn } from 'typeorm';
import { Patient } from './patient.entity.js';
import { AppointmentItem } from './appointment-item.entity.js';

@Entity('appointment')
export class Appointment {
  @PrimaryGeneratedColumn() id: number;
  @Column({ type: 'timestamp' }) apTime: Date;
  @Column({ type: 'timestamp', nullable: true }) confirmDate: Date | null;
  @Column() address: string;
  @Column({ type: 'text', nullable: true }) note: string | null;
  @Column({ type: 'text', nullable: true }) doctorNote: string | null;
  @Column({ default: 1 }) confirmCondition: number;
  @Column({ type: 'text', nullable: true }) cancelReason: string | null;
  @Column({ type: 'varchar', nullable: true }) canceledBy: string | null;
  @Column({ default: false }) rescheduled: boolean;
  @Column() doctorName: string;
  @Column() patientId: number;
  @Column() doctorId: number;
  @Column({ type: 'int', nullable: true }) examFee: number | null;
  @Column({ type: 'int', nullable: true }) total: number | null;
  @Column({ type: 'real', nullable: true }) insuranceRate: number | null;
  @Column({ type: 'int', nullable: true }) insuranceCovered: number | null;
  @Column({ type: 'int', nullable: true }) payable: number | null;
  @Column({ type: 'boolean', nullable: true }) examFeeCovered: boolean | null;
  @OneToMany(() => AppointmentItem, (item) => item.appointment)
  items: AppointmentItem[];
  @ManyToOne(() => Patient)
  @JoinColumn({ name: 'patientId' }) patient: Patient;
}
