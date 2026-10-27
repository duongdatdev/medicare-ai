import { IsIn, IsInt, IsNumber, IsString } from 'class-validator';

export class PayAppointmentDto {
  @IsIn(['cash', 'qr']) method: 'cash' | 'qr';
}

export class SepayWebhookDto {
  @IsInt() id: number;
  @IsString() content: string;
  @IsNumber() transferAmount: number;
  @IsString() transferType: string;
}
