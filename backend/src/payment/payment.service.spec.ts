import { describe, expect, it, vi } from 'vitest';
import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { PaymentService } from './payment.service.js';

describe('PaymentService SePay webhook', () => {
  it('ignores retries with the same SePay transaction ID', async () => {
    const manager = { query: vi.fn().mockResolvedValue([]), save: vi.fn() };
    const transactions = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new PaymentService({} as never, {} as never, transactions as never, { get: () => 'secret' } as never);

    await expect(service.handleWebhook({ id: 801, content: 'DACN12', transferAmount: 50000, transferType: 'in' })).resolves.toEqual({ success: true });

    expect(manager.save).not.toHaveBeenCalled();
  });

  it('marks a matching pending QR payment as paid once', async () => {
    const appointment = { id: 12, paymentStatus: 'pending', paymentMethod: 'qr', payable: 50000, paidAt: null };
    const manager = {
      query: vi.fn().mockResolvedValue([{ id: 1 }]),
      findOne: vi.fn().mockResolvedValue(appointment),
      create: vi.fn((_entity, value) => value),
      save: vi.fn().mockResolvedValue(appointment),
    };
    const transactions = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new PaymentService({} as never, {} as never, transactions as never, { get: () => 'secret' } as never);

    await service.handleWebhook({ id: 802, content: 'DACN12', transferAmount: 50000, transferType: 'in' });

    expect(appointment.paymentStatus).toBe('paid');
    expect(manager.save).toHaveBeenCalledTimes(2);
  });

  it('does not settle a pending invoice when the webhook amount differs', async () => {
    const appointment = { id: 12, paymentStatus: 'pending', paymentMethod: 'qr', payable: 50000, paidAt: null };
    const manager = {
      query: vi.fn().mockResolvedValue([{ id: 1 }]),
      findOne: vi.fn().mockResolvedValue(appointment),
      create: vi.fn((_entity, value) => value),
      save: vi.fn().mockResolvedValue(undefined),
    };
    const transactions = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new PaymentService({} as never, {} as never, transactions as never, { get: () => 'secret' } as never);

    await service.handleWebhook({ id: 803, content: 'DACN12', transferAmount: 49999, transferType: 'in' });

    expect(appointment).toMatchObject({ paymentStatus: 'pending', paidAt: null });
    expect(manager.save).toHaveBeenCalledOnce();
    expect(manager.save).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ title: 'Giao dịch cần kiểm tra', appointmentId: 12 }));
  });

  it('accepts the Apikey authorization scheme and rejects an incorrect secret', () => {
    const service = new PaymentService({} as never, {} as never, {} as never, { get: () => 'expected-secret' } as never);

    expect(() => service.assertWebhookKey('Apikey expected-secret')).not.toThrow();
    expect(() => service.assertWebhookKey('wrong-secret')).toThrow(UnauthorizedException);
  });

  it('fails closed when no webhook key is configured', () => {
    const service = new PaymentService({} as never, {} as never, {} as never, { get: () => undefined } as never);

    expect(() => service.assertWebhookKey('anything')).toThrow(ServiceUnavailableException);
  });
});
