import { IsDateString, IsInt, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateAppointmentDto {
  @IsDateString() apTime: string;
  @IsString() address: string;
  @IsInt() doctorId: number;
  @IsOptional() @IsString() note?: string;
}

export class CancelAppointmentDto {
  @IsString() @MinLength(1) reason: string;
}

export class RescheduleAppointmentDto {
  @IsDateString() apTime: string;
  @IsOptional() @IsString() note?: string;
}
