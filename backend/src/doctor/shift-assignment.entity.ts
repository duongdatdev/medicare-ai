import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

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
}
