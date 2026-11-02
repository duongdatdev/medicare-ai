import { BadRequestException, Body, Controller, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes } from '@nestjs/swagger';
import { ApiTags } from '@nestjs/swagger';
import { Public, Roles } from './auth.decorators.js';
import { LoginDto, RegisterDoctorDto, RegisterPatientDto } from './auth.dto.js';
import { AuthService } from './auth.service.js';
import { BhytService } from '../billing/bhyt.service.js';
import { BhytLookupDto } from '../billing/bhyt.dto.js';

interface UploadedAvatar { buffer: Buffer; mimetype: string; }
const avatarUpload = FileInterceptor('avatar', { limits: { fileSize: 2 * 1024 * 1024 }, fileFilter: (_request, file, callback) => {
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) return callback(new BadRequestException('Ảnh đại diện không hợp lệ'), false);
  callback(null, true);
} });

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
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(avatarUpload)
  register(@Body() input: RegisterPatientDto, @UploadedFile() avatar?: UploadedAvatar) {
    return this.auth.registerPatient(input, avatar);
  }

  @Public()
  @Post('login')
  login(@Body() input: LoginDto) {
    return this.auth.login(input.email, input.password);
  }

  @Roles('admin')
  @Post('register-doctor')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(avatarUpload)
  registerDoctor(@Body() input: RegisterDoctorDto, @UploadedFile() avatar?: UploadedAvatar) {
    if (!avatar) throw new BadRequestException('Ảnh đại diện bác sĩ là bắt buộc');
    return this.auth.registerDoctor(input, avatar);
  }
}
