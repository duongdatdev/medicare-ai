import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('news')
export class News {
  @PrimaryGeneratedColumn() id: number;
  @Column({ length: 200 }) title: string;
  @Column({ length: 2000 }) url: string;
  @Column() imagePath: string;
  @CreateDateColumn() createdAt: Date;
}
