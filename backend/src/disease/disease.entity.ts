import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('disease')
export class Disease {
  @PrimaryGeneratedColumn() id: number;
  @Column({ unique: true }) name: string;
  @Column({ type: 'int' }) price: number;
  @Column({ default: true }) active: boolean;
  @Column({ default: true }) bhytCovered: boolean;
}
