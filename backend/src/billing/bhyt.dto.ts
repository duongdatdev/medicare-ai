import { IsDateString, Matches } from 'class-validator';

export class BhytLookupDto {
  @Matches(/^\d{12}$/) cccd: string;
  @IsDateString() birthDate: string;
}
