import { ArrayNotEmpty, ArrayUnique, IsArray, IsInt } from 'class-validator';

export class CompleteAppointmentDto {
  @IsArray() @ArrayNotEmpty() @ArrayUnique() @IsInt({ each: true }) diseaseIds: number[];
}
