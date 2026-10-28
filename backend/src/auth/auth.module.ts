import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Account } from './account.entity.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { Patient } from '../patient/patient.entity.js';
import { BhytRegistry } from '../billing/bhyt-registry.entity.js';
import { BhytService } from '../billing/bhyt.service.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Account, Patient, BhytRegistry]),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET', 'dev-secret-change-me'),
        signOptions: { expiresIn: config.get('JWT_EXPIRES', '1d') },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, BhytService],
  exports: [JwtModule],
})
export class AuthModule {}
