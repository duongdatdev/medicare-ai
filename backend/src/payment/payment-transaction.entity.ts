import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('payment_transaction')
export class PaymentTransaction {
  @PrimaryGeneratedColumn() id: number;
  @Column({ unique: true }) sepayId: string;
  @Column() content: string;
  @Column({ type: 'int' }) transferAmount: number;
  @CreateDateColumn() createdAt: Date;
}
