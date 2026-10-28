import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('bhyt_registry')
export class BhytRegistry {
  @PrimaryGeneratedColumn() id: number;
  @Column({ length: 12, unique: true }) cccd: string;
  @Column({ length: 15, unique: true }) cardNumber: string;
  @Column() fullName: string;
  @Column({ type: 'date' }) birthDate: string;
  @Column({ type: 'date' }) validFrom: string;
  @Column({ type: 'date' }) validTo: string;
}
