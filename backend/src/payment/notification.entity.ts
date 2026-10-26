import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('notification')
export class Notification {
  @PrimaryGeneratedColumn() id: number;
  @Column() title: string;
  @Column({ type: 'text' }) body: string;
  @CreateDateColumn() createdAt: Date;
  @Column({ type: 'timestamp', nullable: true }) readAt: Date | null;
  @Column({ type: 'int', nullable: true }) appointmentId: number | null;
}
