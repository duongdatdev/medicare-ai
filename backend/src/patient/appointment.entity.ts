import { Column, Entity, ManyToOne, PrimaryGeneratedColumn, JoinColumn } from 'typeorm';
import { Patient } from './patient.entity.js';

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
  @ManyToOne(() => Patient)
  @JoinColumn({ name: 'patientId' }) patient: Patient;
}
