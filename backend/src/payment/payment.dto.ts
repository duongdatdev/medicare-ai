import { IsIn, IsString } from 'class-validator';

export class PayAppointmentDto {
  @IsIn(['cash', 'qr']) method: 'cash' | 'qr';
}

export class SepayWebhookDto {
  @IsString() id: string;
  @IsString() content: string;
  amount: number;
  transferType: string;
}
