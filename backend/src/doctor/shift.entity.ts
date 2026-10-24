import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('shift')
export class Shift {
  @PrimaryGeneratedColumn() id: number;
  @Column({ unique: true }) type: string;
  @Column({ type: 'time' }) startTime: string;
  @Column({ type: 'time' }) endTime: string;
}
