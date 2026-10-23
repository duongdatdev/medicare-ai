import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('account')
export class Account {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true }) email: string;
  @Column() passwordHash: string;
  @Column() role: 'admin' | 'doctor' | 'patient';
  @Column({ nullable: true }) patientId: number | null;
  @Column({ nullable: true }) doctorId: number | null;
}
