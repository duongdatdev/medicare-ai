import { IsDateString, IsEmail, IsIn, IsInt, IsString, Matches, MinLength } from 'class-validator';

export class RegisterPatientDto {
  @IsEmail() email: string;
  @MinLength(8) password: string;
  @IsString() name: string;
  @IsIn(['male', 'female', 'other']) gender: string;
  @IsInt() age: number;
  @IsDateString() birthDate: string;
  @IsString() phone: string;
  @IsString() address: string;
  @Matches(/^\d{12}$/) cccd: string;
}

export class LoginDto {
  @IsEmail() email: string;
  @IsString() password: string;
}
