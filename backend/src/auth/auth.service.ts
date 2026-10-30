import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import { Account } from './account.entity.js';
import { RegisterDoctorDto, RegisterPatientDto } from './auth.dto.js';
import { Patient } from '../patient/patient.entity.js';
import { Doctor } from '../doctor/doctor.entity.js';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Account) private readonly accounts: Repository<Account>,
    @InjectRepository(Patient) private readonly patients: Repository<Patient>,
    @InjectRepository(Doctor) private readonly doctors: Repository<Doctor>,
    private readonly jwt: JwtService,
  ) {}

  async registerPatient(input: RegisterPatientDto) {
    return this.accounts.manager.transaction(async (manager) => {
      const duplicateEmail = await manager.exists(Account, { where: { email: input.email } });
      if (duplicateEmail) throw new ConflictException('Email đã tồn tại');
      const duplicateCccd = await manager.exists(Patient, { where: { cccd: input.cccd } });
      if (duplicateCccd) throw new ConflictException('CCCD đã được đăng ký');
      const patient = await manager.save(Patient, {
        ...input,
        avatar: '',
      });
      const account = await manager.save(Account, {
        email: input.email,
        passwordHash: await bcrypt.hash(input.password, 10),
        role: 'patient',
        patientId: patient.id,
        doctorId: null,
      });
      return this.createSession(account, patient.name, patient.avatar);
    });
  }

  async login(email: string, password: string) {
    const account = await this.accounts.findOneBy({ email });
    if (!account || !(await bcrypt.compare(password, account.passwordHash))) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }
    const patient = account.patientId
      ? await this.patients.findOneBy({ id: account.patientId })
      : null;
    return this.createSession(account, patient?.name ?? 'Admin', patient?.avatar ?? null);
  }

  async registerDoctor(input: RegisterDoctorDto) {
    return this.accounts.manager.transaction(async (manager) => {
      if (await manager.exists(Account, { where: { email: input.email } })) throw new ConflictException('Email đã tồn tại');
      const doctor = await manager.save(Doctor, { ...input, dateOfBirth: new Date(input.dateOfBirth), avatar: '' });
      const account = await manager.save(Account, {
        email: input.email, passwordHash: await bcrypt.hash(input.password, 10), role: 'doctor',
        doctorId: doctor.id, patientId: null,
      });
      return { id: account.id, doctorId: doctor.id, email: input.email, role: 'doctor' };
    });
  }

  private createSession(account: Account, name: string, avatarUrl: string | null) {
    const claims = {
      sub: account.id,
      role: account.role,
      patientId: account.patientId ?? undefined,
      doctorId: account.doctorId ?? undefined,
    };
    return {
      accessToken: this.jwt.sign(claims),
      role: account.role,
      patientId: claims.patientId,
      doctorId: claims.doctorId,
      name,
      avatarUrl: avatarUrl || null,
    };
  }
}
