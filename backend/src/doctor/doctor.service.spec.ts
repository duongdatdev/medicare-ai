import { describe, expect, it, vi } from 'vitest';
import { DoctorService } from './doctor.service.js';
import { ConflictException } from '@nestjs/common';

describe('DoctorService availability', () => {
  it('lists 30-minute slots only inside assigned shifts and removes booked slots', async () => {
    const appointments = { find: vi.fn().mockResolvedValue([
      { apTime: new Date('2026-11-12T00:30:00Z'), cancelReason: null },
      { apTime: new Date('2026-11-12T01:00:00Z'), cancelReason: 'cancelled' },
    ]) };
    const assignments = { find: vi.fn().mockResolvedValue([
      { startTime: new Date('2026-11-12T00:00:00Z'), endTime: new Date('2026-11-12T01:30:00Z'), status: 'ACTIVE' },
    ]) };
    const service = new DoctorService({} as never, appointments as never, assignments as never, {} as never);

    const result = await service.availability(4, '2026-11-12');

    expect(result).toEqual(['2026-11-12T00:00:00.000Z', '2026-11-12T01:00:00.000Z']);
  });

  it('rejects duplicate diagnosis IDs before writing an invoice', async () => {
    const manager = { transaction: vi.fn() };
    const appointments = { manager };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never);

    await expect(service.completeAppointment(4, 9, { diseaseIds: [2, 2] })).rejects.toBeInstanceOf(ConflictException);
    expect(manager.transaction).not.toHaveBeenCalled();
  });

  it('calculates salary from full active shifts and recorded partial hours', async () => {
    const doctors = { find: vi.fn().mockResolvedValue([{ id: 4, name: 'Doctor' }]) };
    const assignments = { find: vi.fn().mockResolvedValue([
      { doctorId: 4, status: 'ACTIVE', startTime: new Date('2026-11-12T00:00:00Z'), endTime: new Date('2026-11-12T04:00:00Z'), duration: 0 },
      { doctorId: 4, status: 'CANCELED', duration: 1.5 },
    ]) };
    const service = new DoctorService(doctors as never, {} as never, assignments as never, {} as never, {} as never, {} as never);

    await expect(service.salaries(300000)).resolves.toEqual([
      { doctorId: 4, doctorName: 'Doctor', totalHours: 5.5, hourlyRate: 300000, salary: 1650000 },
    ]);
  });
});
