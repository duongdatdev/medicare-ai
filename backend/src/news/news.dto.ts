import { IsString, IsUrl, MaxLength, MinLength } from 'class-validator';

export class CreateNewsDto {
  @IsString() @MinLength(1) @MaxLength(200) title: string;
  @IsUrl({ protocols: ['http', 'https'], require_protocol: true }) @MaxLength(2000) url: string;
}
