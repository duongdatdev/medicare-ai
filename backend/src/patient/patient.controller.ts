import { Body, Controller, Get, Param, ParseIntPipe, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../auth/auth.decorators.js';
import { Appointment } from './appointment.entity.js';
import { CancelAppointmentDto, CreateAppointmentDto, RescheduleAppointmentDto } from './appointment.dto.js';
import { PatientService } from './patient.service.js';

@ApiTags('patient')
@ApiBearerAuth()
@Roles('patient')
@Controller('patient')
export class PatientController {
  constructor(private readonly patients: PatientService) {}

  @Get('me') getProfile(@CurrentUser() user: { patientId: number }) {
    return this.patients.getProfile(user.patientId);
  }

  @Put('me') updateProfile(@CurrentUser() user: { patientId: number }, @Body() changes: Record<string, unknown>) {
    const allowed = ['name', 'gender', 'age', 'birthDate', 'phone', 'address', 'avatar'];
    return this.patients.updateProfile(user.patientId, Object.fromEntries(Object.entries(changes).filter(([key]) => allowed.includes(key))));
  }

  @Post('create-appointment') create(@CurrentUser() user: { patientId: number }, @Body() input: CreateAppointmentDto) {
    return this.patients.createAppointment(user.patientId, input);
  }

  @Get('list-appointment') list(@CurrentUser() user: { patientId: number }) {
    return this.patients.listAppointments(user.patientId);
  }

  @Get('appointment/:id') detail(@CurrentUser() user: { patientId: number }, @Param('id', ParseIntPipe) id: number) {
    return this.patients.getAppointment(user.patientId, id);
  }

  @Post('cancel-appointment/:id') cancel(@CurrentUser() user: { patientId: number }, @Param('id', ParseIntPipe) id: number, @Body() input: CancelAppointmentDto) {
    return this.patients.cancelAppointment(user.patientId, id, input.reason);
  }

  @Put('reschedule-appointment/:id') reschedule(@CurrentUser() user: { patientId: number }, @Param('id', ParseIntPipe) id: number, @Body() input: RescheduleAppointmentDto) {
    return this.patients.rescheduleAppointment(user.patientId, id, input);
  }
}
