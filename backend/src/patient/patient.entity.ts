import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('patient')
export class Patient {
  @PrimaryGeneratedColumn()
  id: number;

  @Column() name: string;
  @Column() gender: string;
  @Column() age: number;
  @Column({ type: 'date' }) birthDate: string;
  @Column() email: string;
  @Column() phone: string;
  @Column() address: string;
  @Column({ default: '' }) avatar: string;
  @Column({ length: 12, unique: true }) cccd: string;
}
