import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../auth/auth.decorators.js';
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

  @Roles('doctor')
  @Get('shift-templates') templates() {
    return this.doctors.shiftTemplates();
  }

  @Roles('doctor')
  @Post('register-shift')
  registerShift(@CurrentUser() user: { doctorId: number }, @Body() input: { shiftId: number; date: string }) {
    return this.doctors.registerShift(user.doctorId, input.shiftId, input.date);
  }

  @Roles('doctor')
  @Get('list-unAcpappointment')
  pending(@CurrentUser() user: { doctorId: number }) {
    return this.doctors.listAppointments(user.doctorId, 1);
  }

  @Roles('doctor')
  @Get('list-appointment')
  confirmed(@CurrentUser() user: { doctorId: number }) {
    return this.doctors.listAppointments(user.doctorId, 0);
  }

  @Roles('doctor')
  @Get('list-completed')
  completed(@CurrentUser() user: { doctorId: number }) {
    return this.doctors.listAppointments(user.doctorId, 2);
  }

  @Roles('doctor')
  @Post('confirm-appointment/:id')
  confirm(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number, @Body() body: { note?: string }) {
    return this.doctors.confirmAppointment(user.doctorId, id, body.note);
  }
}
