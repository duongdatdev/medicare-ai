import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../auth/auth.decorators.js';
import { CreateDiseaseDto, UpdateDiseaseDto } from './disease.dto.js';
import { DiseaseService } from './disease.service.js';

@ApiTags('diseases')
@ApiBearerAuth()
@Controller('diseases')
export class DiseaseController {
  constructor(private readonly diseases: DiseaseService) {}

  @Roles('admin', 'doctor')
  @Get() list(@CurrentUser() user: { role: string }) { return this.diseases.list(user.role); }

  @Roles('admin')
  @Post()
  create(@Body() input: CreateDiseaseDto) { return this.diseases.create(input); }

  @Roles('admin')
  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() input: UpdateDiseaseDto) {
    return this.diseases.update(id, input);
  }
}
