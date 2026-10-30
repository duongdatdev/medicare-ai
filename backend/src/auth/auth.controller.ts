import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public, Roles } from './auth.decorators.js';
import { LoginDto, RegisterDoctorDto, RegisterPatientDto } from './auth.dto.js';
import { AuthService } from './auth.service.js';
import { BhytService } from '../billing/bhyt.service.js';
import { BhytLookupDto } from '../billing/bhyt.dto.js';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService, private readonly bhyt: BhytService) {}

  @Public()
  @Post('bhyt-lookup')
  lookup(@Body() input: BhytLookupDto) {
    return this.bhyt.lookup(input.cccd, input.birthDate);
  }

  @Public()
  @Post('register')
  register(@Body() input: RegisterPatientDto) {
    return this.auth.registerPatient(input);
  }

  @Public()
  @Post('login')
  login(@Body() input: LoginDto) {
    return this.auth.login(input.email, input.password);
  }

  @Roles('admin')
  @Post('register-doctor')
  registerDoctor(@Body() input: RegisterDoctorDto) {
    return this.auth.registerDoctor(input);
  }
}
