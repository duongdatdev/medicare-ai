import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import { Account } from './account.entity.js';
import { RegisterDoctorDto, RegisterPatientDto } from './auth.dto.js';
import { Patient } from '../patient/patient.entity.js';
import { Doctor } from '../doctor/doctor.entity.js';
import { randomUUID } from 'node:crypto';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

interface UploadedAvatar { buffer: Buffer; mimetype: string; }

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Account) private readonly accounts: Repository<Account>,
    @InjectRepository(Patient) private readonly patients: Repository<Patient>,
    @InjectRepository(Doctor) private readonly doctors: Repository<Doctor>,
    private readonly jwt: JwtService,
  ) {}

  async registerPatient(input: RegisterPatientDto, avatar?: UploadedAvatar) {
    const avatarPath = avatar ? await this.saveAvatar(avatar) : '';
    try { return await this.accounts.manager.transaction(async (manager) => {
      const duplicateEmail = await manager.exists(Account, { where: { email: input.email } });
      if (duplicateEmail) throw new ConflictException('Email đã tồn tại');
      const duplicateCccd = await manager.exists(Patient, { where: { cccd: input.cccd } });
      if (duplicateCccd) throw new ConflictException('CCCD đã được đăng ký');
      const patient = await manager.save(Patient, {
        ...input,
        avatar: avatarPath,
      });
      const account = await manager.save(Account, {
        email: input.email,
        passwordHash: await bcrypt.hash(input.password, 10),
        role: 'patient',
        patientId: patient.id,
        doctorId: null,
      });
      return this.createSession(account, patient.name, patient.avatar);
    }); } catch (error) { if (avatarPath) await rm(join(process.cwd(), avatarPath.replace(/^\/+/, '')), { force: true }); throw error; }
  }

  async login(email: string, password: string) {
    const account = await this.accounts.findOneBy({ email });
    if (!account || !(await bcrypt.compare(password, account.passwordHash))) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }
    const patient = account.patientId
      ? await this.patients.findOneBy({ id: account.patientId })
      : null;
    const doctor = account.doctorId
      ? await this.doctors.findOneBy({ id: account.doctorId })
      : null;
    return this.createSession(account, patient?.name ?? doctor?.name ?? 'Admin', patient?.avatar ?? doctor?.avatar ?? null);
  }

  async registerDoctor(input: RegisterDoctorDto, avatar: UploadedAvatar) {
    const avatarPath = await this.saveAvatar(avatar);
    try { return await this.accounts.manager.transaction(async (manager) => {
      if (await manager.exists(Account, { where: { email: input.email } })) throw new ConflictException('Email đã tồn tại');
      const doctor = await manager.save(Doctor, { ...input, dateOfBirth: new Date(input.dateOfBirth), avatar: avatarPath });
      const account = await manager.save(Account, {
        email: input.email, passwordHash: await bcrypt.hash(input.password, 10), role: 'doctor',
        doctorId: doctor.id, patientId: null,
      });
      return { id: account.id, doctorId: doctor.id, email: input.email, role: 'doctor' };
    }); } catch (error) { await rm(join(process.cwd(), avatarPath.replace(/^\/+/, '')), { force: true }); throw error; }
  }

  private async saveAvatar(image: UploadedAvatar) {
    const extension = image.mimetype === 'image/png' ? '.png' : image.mimetype === 'image/webp' ? '.webp' : '.jpg';
    const filename = `${randomUUID()}${extension}`;
    const directory = join(process.cwd(), 'uploads', 'avatars');
    await mkdir(directory, { recursive: true });
    await writeFile(join(directory, filename), image.buffer, { flag: 'wx' });
    return `/uploads/avatars/${filename}`;
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
