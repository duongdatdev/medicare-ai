import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query, Put, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../auth/auth.decorators.js';
import { DoctorService } from './doctor.service.js';
import { CompleteAppointmentDto } from './doctor.dto.js';
import { CreateDoctorDto, UpdateDoctorDto } from './doctor.dto.js';
import type { Response } from 'express';

@ApiTags('doctor')
@ApiBearerAuth()
@Controller('doctor')
export class DoctorController {
  constructor(private readonly doctors: DoctorService) {}

  @Get('list') list() {
    return this.doctors.list();
  }

  @Roles('admin')
  @Post('register-admin')
  createDoctor(@Body() input: CreateDoctorDto) { return this.doctors.createDoctor(input); }

  @Roles('admin')
  @Get('detail/:id')
  doctorDetail(@Param('id', ParseIntPipe) id: number) { return this.doctors.getDoctor(id); }

  @Roles('admin')
  @Put('update/:id')
  updateDoctor(@Param('id', ParseIntPipe) id: number, @Body() input: UpdateDoctorDto) { return this.doctors.updateDoctor(id, input); }

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
  @Get('my-shifts') myShifts(@CurrentUser() user: { doctorId: number }) { return this.doctors.myShifts(user.doctorId); }

  @Roles('doctor', 'admin')
  @Get('shift-overview') shiftOverview() { return this.doctors.shiftOverview(); }

  @Roles('doctor')
  @Post('cancel-assignment/:id') cancelAssignment(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number) {
    return this.doctors.cancelAssignment(user.doctorId, id);
  }

  @Roles('doctor')
  @Delete('assignment/:id') deleteAssignment(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number) {
    return this.doctors.deleteAssignment(user.doctorId, id);
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
  @Get('report/:appointmentId')
  async report(@Param('appointmentId', ParseIntPipe) id: number, @Res() response: Response) {
    const pdf = await this.doctors.getReport(id);
    if (!pdf) return response.status(404).end();
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': `attachment; filename="report-${id}.pdf"` });
    response.end(pdf);
  }

  @Roles('doctor')
  @Post('confirm-appointment/:id')
  confirm(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number, @Body() body: { note?: string }) {
    return this.doctors.confirmAppointment(user.doctorId, id, body.note);
  }

  @Roles('doctor')
  @Post('cancel-appointment/:id')
  cancelAppointment(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number, @Body() body: { reason: string }) {
    return this.doctors.cancelAppointment(user.doctorId, id, body.reason);
  }

  @Roles('doctor')
  @Put('reschedule-appointment/:id')
  rescheduleAppointment(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number, @Body() body: { apTime: string }) {
    return this.doctors.rescheduleAppointment(user.doctorId, id, body.apTime);
  }

  @Roles('doctor')
  @Post('re-examination')
  reExamination(@CurrentUser() user: { doctorId: number }, @Body() body: { patientId: number; apTime: string; address: string; note?: string }) {
    return this.doctors.reExamination(user.doctorId, body.patientId, body.apTime, body.address, body.note);
  }

  @Roles('doctor')
  @Post('complete/:id')
  complete(@CurrentUser() user: { doctorId: number }, @Param('id', ParseIntPipe) id: number, @Body() input: CompleteAppointmentDto) {
    return this.doctors.completeAppointment(user.doctorId, id, input);
  }
}
