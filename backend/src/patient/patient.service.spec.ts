import { ConflictException, ForbiddenException } from '@nestjs/common';
import { describe, expect, it, vi } from 'vitest';
import { PatientService } from './patient.service.js';
import { QueryFailedError } from 'typeorm';

describe('PatientService', () => {
  it('creates a new appointment in the pending state', async () => {
    const appointment = { apTime: new Date('2026-11-12T02:00:00Z'), confirmCondition: 1 };
    const appointments = { create: vi.fn((value) => value), save: vi.fn().mockResolvedValue(appointment) };
    const service = new PatientService({} as never, appointments as never);

    const result = await service.createAppointment(8, {
      apTime: '2026-11-12T02:00:00Z', address: 'Clinic', doctorId: 3, note: 'Checkup',
    });

    expect(result.confirmCondition).toBe(1);
    expect(appointments.save).toHaveBeenCalledWith(expect.objectContaining({ patientId: 8, doctorId: 3 }));
  });

  it('rejects a booked slot as a conflict', async () => {
    const dbError = new QueryFailedError('INSERT', [], { code: '23505' });
    const appointments = { create: vi.fn((value) => value), save: vi.fn().mockRejectedValue(dbError) };
    const service = new PatientService({} as never, appointments as never);

    await expect(service.createAppointment(8, {
      apTime: '2026-11-12T02:00:00Z', address: 'Clinic', doctorId: 3,
    })).rejects.toBeInstanceOf(ConflictException);
  });

  it('denies access to another patient’s appointment', async () => {
    const appointments = {
      findOne: vi.fn().mockResolvedValue({ id: 4, patientId: 9 }),
    };
    const service = new PatientService({} as never, appointments as never, {} as never);

    await expect(service.getAppointment(8, 4)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('does not reschedule a canceled appointment or query available slots', async () => {
    const appointments = {
      findOne: vi.fn().mockResolvedValue({ id: 4, patientId: 8, confirmCondition: 1, cancelReason: 'busy' }),
      manager: { query: vi.fn() },
    };
    const service = new PatientService({} as never, appointments as never, {} as never);

    await expect(service.rescheduleAppointment(8, 4, { apTime: '2026-11-12T02:00:00Z' })).rejects.toBeInstanceOf(ConflictException);
    expect(appointments.manager.query).not.toHaveBeenCalled();
  });

  it('moves a confirmed appointment back to pending after rescheduling into a free slot', async () => {
    const appointment = { id: 4, patientId: 8, doctorId: 3, confirmCondition: 0, rescheduled: false, cancelReason: null, note: null };
    const appointments = {
      findOne: vi.fn().mockResolvedValue(appointment),
      manager: { query: vi.fn().mockResolvedValue([{ '?column?': 1 }]) },
      save: vi.fn(async (value) => value),
    };
    const service = new PatientService({} as never, appointments as never, {} as never);

    await expect(service.rescheduleAppointment(8, 4, { apTime: '2026-11-13T02:00:00Z', note: 'New time' })).resolves.toMatchObject({
      apTime: new Date('2026-11-13T02:00:00Z'), confirmCondition: 1, rescheduled: true, note: 'New time',
    });
    expect(appointments.manager.query).toHaveBeenCalledWith(expect.stringContaining('a."id" <> $3'), [3, '2026-11-13T02:00:00Z', 4]);
  });
});
