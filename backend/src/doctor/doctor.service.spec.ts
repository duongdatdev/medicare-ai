import { describe, expect, it, vi } from 'vitest';
import { DoctorService } from './doctor.service.js';
import { BadRequestException, ConflictException } from '@nestjs/common';

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

  it('stops a canceled shift at the cancellation time and records worked hours', async () => {
    const startTime = new Date(Date.now() - 90 * 60_000);
    const endTime = new Date(Date.now() + 60 * 60_000);
    const assignment = { startTime, endTime, status: 'ACTIVE', duration: 0 };
    const assignments = { findOneBy: vi.fn().mockResolvedValue(assignment), save: vi.fn().mockResolvedValue(assignment) };
    const service = new DoctorService({} as never, {} as never, assignments as never, {} as never, {} as never, {} as never, {} as never);

    await service.cancelShift(4, 2);

    expect(assignment.status).toBe('CANCELED');
    expect(assignment.duration).toBeCloseTo(1.5, 1);
    expect(endTime.getTime() - assignment.endTime.getTime()).toBeGreaterThan(0);
  });

  it('rejects a shift date that is not in the future', async () => {
    const shifts = { findOneBy: vi.fn().mockResolvedValue({ id: 3, startTime: '09:00:00', endTime: '12:00:00', type: 'morning' }) };
    const assignments = { findOneBy: vi.fn(), count: vi.fn(), save: vi.fn() };
    const service = new DoctorService({} as never, {} as never, assignments as never, shifts as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    await expect(service.registerShift(4, 3, '2020-01-01')).rejects.toBeInstanceOf(BadRequestException);
    expect(assignments.count).not.toHaveBeenCalled();
  });

  it('rejects registration after the four doctor capacity is reached', async () => {
    const shifts = { findOneBy: vi.fn().mockResolvedValue({ id: 3, startTime: '09:00:00', endTime: '12:00:00', type: 'morning' }) };
    const assignments = { findOneBy: vi.fn().mockResolvedValue(null), count: vi.fn().mockResolvedValue(4), save: vi.fn() };
    const service = new DoctorService({} as never, {} as never, assignments as never, shifts as never, {} as never, {} as never, {} as never, {} as never, {} as never);
    const futureDate = new Date(Date.now() + 10 * 86400000).toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' });

    await expect(service.registerShift(4, 3, futureDate)).rejects.toBeInstanceOf(ConflictException);
    expect(assignments.count).toHaveBeenCalledWith(expect.objectContaining({ where: expect.objectContaining({ shiftId: 3, status: 'ACTIVE' }) }));
    expect(assignments.save).not.toHaveBeenCalled();
  });
});
