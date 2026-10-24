import { IsBoolean, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateDiseaseDto {
  @IsString() @MinLength(1) name: string;
  @IsInt() @Min(0) price: number;
  @IsOptional() @IsBoolean() bhytCovered?: boolean;
}

export class UpdateDiseaseDto {
  @IsOptional() @IsString() @MinLength(1) name?: string;
  @IsOptional() @IsInt() @Min(0) price?: number;
  @IsOptional() @IsBoolean() active?: boolean;
  @IsOptional() @IsBoolean() bhytCovered?: boolean;
}
