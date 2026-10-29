import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../auth/auth.decorators.js';
import { DoctorService } from './doctor.service.js';

@ApiTags('admin')
@ApiBearerAuth()
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly doctors: DoctorService) {}

  @Get('doctor-salaries')
  salaries(@Query('hourlyRate') rate?: string) {
    return this.doctors.salaries(Number(rate) || 300000);
  }
}
