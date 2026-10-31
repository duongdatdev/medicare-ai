import { ArrayNotEmpty, ArrayUnique, IsArray, IsInt } from 'class-validator';
import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CompleteAppointmentDto {
  @IsArray() @ArrayNotEmpty() @ArrayUnique() @IsInt({ each: true }) diseaseIds: number[];
}

export class CreateDoctorDto {
  @IsEmail() email: string;
  @MinLength(8) password: string;
  @IsString() name: string;
  @IsInt() age: number;
  @IsString() dateOfBirth: string;
  @IsIn(['male', 'female', 'other']) gender: string;
  @IsString() phone: string;
  @IsString() address: string;
}

export class UpdateDoctorDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsInt() age?: number;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() address?: string;
}

export class CancelShiftDto {
  @IsInt() shiftId: number;
}
