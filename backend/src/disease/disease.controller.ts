import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../auth/auth.decorators.js';
import { CreateDiseaseDto, UpdateDiseaseDto } from './disease.dto.js';
import { DiseaseService } from './disease.service.js';

@ApiTags('diseases')
@ApiBearerAuth()
@Controller('diseases')
export class DiseaseController {
  constructor(private readonly diseases: DiseaseService) {}

  @Get() list() { return this.diseases.list(); }

  @Roles('admin')
  @Post()
  create(@Body() input: CreateDiseaseDto) { return this.diseases.create(input); }

  @Roles('admin')
  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() input: UpdateDiseaseDto) {
    return this.diseases.update(id, input);
  }
}
