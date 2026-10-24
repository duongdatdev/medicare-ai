import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('doctor')
export class Doctor {
  @PrimaryGeneratedColumn() id: number;
  @Column() name: string;
  @Column() age: number;
  @Column({ type: 'timestamp' }) dateOfBirth: Date;
  @Column() gender: string;
  @Column() phone: string;
  @Column() address: string;
  @Column({ unique: true }) email: string;
  @Column({ default: '' }) avatar: string;
}
