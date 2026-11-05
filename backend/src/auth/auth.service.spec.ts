import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { describe, expect, it, vi } from 'vitest';
import { AuthService } from './auth.service.js';

describe('AuthService login', () => {
  it('returns a patient session with account-linked JWT claims', async () => {
    const account = { id: 17, email: 'patient@example.test', passwordHash: await bcrypt.hash('correct-password', 4), role: 'patient', patientId: 8, doctorId: null };
    const accounts = { findOneBy: vi.fn().mockResolvedValue(account) };
    const patients = { findOneBy: vi.fn().mockResolvedValue({ id: 8, name: 'Patient Name', avatar: '/uploads/patient.jpg' }) };
    const jwt = { sign: vi.fn().mockReturnValue('signed-token') };
    const service = new AuthService(accounts as never, patients as never, {} as never, jwt as never);

    await expect(service.login(account.email, 'correct-password')).resolves.toEqual({
      accessToken: 'signed-token', role: 'patient', patientId: 8, doctorId: undefined,
      name: 'Patient Name', avatarUrl: '/uploads/patient.jpg',
    });
    expect(jwt.sign).toHaveBeenCalledWith({ sub: 17, role: 'patient', patientId: 8, doctorId: undefined });
  });

  it('rejects unknown accounts and incorrect passwords with the same response', async () => {
    const accounts = { findOneBy: vi.fn().mockResolvedValueOnce(null).mockResolvedValueOnce({ passwordHash: await bcrypt.hash('correct-password', 4) }) };
    const service = new AuthService(accounts as never, {} as never, {} as never, {} as never);

    await expect(service.login('missing@example.test', 'guess')).rejects.toBeInstanceOf(UnauthorizedException);
    await expect(service.login('known@example.test', 'wrong-password')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
