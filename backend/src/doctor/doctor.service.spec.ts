import { describe, expect, it, vi } from 'vitest';
import { DoctorService } from './doctor.service.js';
import { BadRequestException, ConflictException, ForbiddenException } from '@nestjs/common';

describe('DoctorService availability', () => {
  it('includes patient details when returning a doctor’s appointments', async () => {
    const appointments = { find: vi.fn().mockResolvedValue([]) };
    const service = new DoctorService(
      {} as never,
      appointments as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await service.listAppointments(4, 1);

    expect(appointments.find).toHaveBeenCalledWith({
      where: { doctorId: 4, confirmCondition: 1 },
      relations: { patient: true },
      order: { apTime: 'ASC' },
    });
  });

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

  it('denies a doctor canceling an appointment owned by another doctor', async () => {
    const appointments = { findOneBy: vi.fn().mockResolvedValue({ id: 9, doctorId: 5, confirmCondition: 1, cancelReason: null }), save: vi.fn() };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    await expect(service.cancelAppointment(4, 9, 'reason')).rejects.toBeInstanceOf(ForbiddenException);
    expect(appointments.save).not.toHaveBeenCalled();
  });

  it('retains a canceled appointment while recording its reason and actor', async () => {
    const appointment = { id: 9, doctorId: 4, confirmCondition: 1, cancelReason: null, canceledBy: null };
    const appointments = { findOneBy: vi.fn().mockResolvedValue(appointment), save: vi.fn(async (value) => value) };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    await expect(service.cancelAppointment(4, 9, 'Doctor unavailable')).resolves.toMatchObject({
      id: 9, confirmCondition: 1, cancelReason: 'Doctor unavailable', canceledBy: 'doctor',
    });
    expect(appointments.save).toHaveBeenCalledOnce();
  });

  it('allows one reschedule into an available slot and marks it as used', async () => {
    const appointment = { id: 9, doctorId: 4, confirmCondition: 0, rescheduled: false, cancelReason: null, apTime: new Date('2026-11-12T01:00:00Z') };
    const appointments = { findOneBy: vi.fn().mockResolvedValue(appointment), save: vi.fn(async (value) => value) };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);
    const availableAt = '2026-11-13T01:30:00.000Z';
    vi.spyOn(service, 'availability').mockResolvedValue([availableAt]);

    await expect(service.rescheduleAppointment(4, 9, availableAt)).resolves.toMatchObject({ apTime: new Date(availableAt), rescheduled: true });
    expect(appointments.save).toHaveBeenCalledOnce();
  });

  it('stores BHYT billing snapshots and disease line items when completing an appointment', async () => {
    const appointment = { id: 9, doctorId: 4, patientId: 8, confirmCondition: 0, cancelReason: null, paymentStatus: 'unpaid', apTime: new Date('2026-11-12T00:00:00Z') };
    const patient = { id: 8, cccd: '012345678901', birthDate: '1990-01-01' };
    const card = { cardNumber: 'AB3123456789012', validFrom: '2026-01-01', validTo: '2026-12-31' };
    const disease = { id: 2, name: 'Test condition', price: 100000, bhytCovered: true, active: true };
    const manager = {
      findOne: vi.fn().mockResolvedValue(appointment),
      findBy: vi.fn().mockResolvedValue([disease]),
      findOneBy: vi.fn().mockResolvedValueOnce(patient).mockResolvedValueOnce(card),
      save: vi.fn(async (_entity, value) => value),
    };
    const appointments = { manager: { transaction: vi.fn((work) => work(manager)) } };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    const result = await service.completeAppointment(4, 9, { diseaseIds: [2] });

    expect(result).toMatchObject({ confirmCondition: 2, examFee: 50000, total: 150000, insuranceRate: 0.95, insuranceCovered: 142500, payable: 7500, insuranceCardNumber: card.cardNumber });
    expect(manager.save).toHaveBeenNthCalledWith(1, expect.objectContaining({ paymentStatus: 'unpaid', payable: 7500 }));
    expect(manager.save).toHaveBeenNthCalledWith(2, expect.anything(), [expect.objectContaining({ name: disease.name, appointmentId: 9 })]);
  });

  it('rejects a doctor reschedule when the requested slot is no longer available', async () => {
    const appointment = { id: 9, doctorId: 4, confirmCondition: 0, rescheduled: false, cancelReason: null, apTime: new Date('2026-11-12T01:00:00Z') };
    const appointments = { findOneBy: vi.fn().mockResolvedValue(appointment), save: vi.fn() };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);
    vi.spyOn(service, 'availability').mockResolvedValue([]);

    await expect(service.rescheduleAppointment(4, 9, '2026-11-13T01:30:00Z')).rejects.toBeInstanceOf(ConflictException);
    expect(appointment.apTime).toEqual(new Date('2026-11-12T01:00:00Z'));
    expect(appointments.save).not.toHaveBeenCalled();
  });

  it('prevents a doctor from completing another doctor’s appointment', async () => {
    const manager = { findOne: vi.fn().mockResolvedValue({ id: 9, doctorId: 5, confirmCondition: 0, cancelReason: null }), save: vi.fn() };
    const appointments = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    await expect(service.completeAppointment(4, 9, { diseaseIds: [2] })).rejects.toBeInstanceOf(ForbiddenException);
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('marks a fully covered completed invoice as paid without opening payment collection', async () => {
    const appointment = { id: 9, doctorId: 4, patientId: 8, confirmCondition: 0, cancelReason: null, paymentStatus: 'unpaid', apTime: new Date('2026-11-12T00:00:00Z') };
    const manager = {
      findOne: vi.fn().mockResolvedValue(appointment),
      findBy: vi.fn().mockResolvedValue([{ id: 2, name: 'Covered condition', price: 10000, bhytCovered: true, active: true }]),
      findOneBy: vi.fn().mockResolvedValueOnce({ id: 8, cccd: '012345678901', birthDate: '1990-01-01' })
        .mockResolvedValueOnce({ cardNumber: 'AB1123456789012', validFrom: '2026-01-01', validTo: '2026-12-31' }),
      save: vi.fn(async (_entity, value) => value),
    };
    const appointments = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new DoctorService({} as never, appointments as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never, {} as never);

    const result = await service.completeAppointment(4, 9, { diseaseIds: [2] });

    expect(result.payable).toBe(0);
    expect(appointment).toMatchObject({ paymentStatus: 'paid', payable: 0 });
    expect(appointment.paidAt).toBeInstanceOf(Date);
  });
});
