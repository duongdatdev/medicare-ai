import { Controller, Get, Query, ParseIntPipe } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DoctorService } from './doctor.service.js';

@ApiTags('doctor')
@ApiBearerAuth()
@Controller('doctor')
export class DoctorController {
  constructor(private readonly doctors: DoctorService) {}

  @Get('list') list() {
    return this.doctors.list();
  }

  @Get('availability') availability(
    @Query('doctorId', ParseIntPipe) doctorId: number,
    @Query('date') date: string,
  ) {
    return this.doctors.availability(doctorId, date);
  }
}
