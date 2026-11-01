import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Doctor } from './doctor.entity.js';
import { Shift } from './shift.entity.js';

@Entity('shiftAssignment')
export class ShiftAssignment {
  @PrimaryGeneratedColumn() id: number;
  @Column() type: string;
  @Column({ type: 'timestamp' }) startTime: Date;
  @Column({ type: 'timestamp' }) endTime: Date;
  @Column({ default: 'ACTIVE' }) status: string;
  @Column({ type: 'float', default: 0 }) duration: number;
  @Column() doctorId: number;
  @Column() shiftId: number;
  @ManyToOne(() => Doctor)
  @JoinColumn({ name: 'doctorId' }) doctor: Doctor;
  @ManyToOne(() => Shift)
  @JoinColumn({ name: 'shiftId' }) shift: Shift;
}
