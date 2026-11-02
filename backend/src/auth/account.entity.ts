import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('account')
export class Account {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true }) email: string;
  @Column() passwordHash: string;
  @Column() role: 'admin' | 'doctor' | 'patient';
  @Column({ type: 'int', nullable: true }) patientId: number | null;
  @Column({ type: 'int', nullable: true }) doctorId: number | null;
}
