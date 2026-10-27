import { describe, expect, it, vi } from 'vitest';
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
      save: vi.fn().mockResolvedValue(appointment),
    };
    const transactions = { manager: { transaction: (work: (manager: typeof manager) => unknown) => work(manager) } };
    const service = new PaymentService({} as never, {} as never, transactions as never, { get: () => 'secret' } as never);

    await service.handleWebhook({ id: 802, content: 'DACN12', transferAmount: 50000, transferType: 'in' });

    expect(appointment.paymentStatus).toBe('paid');
    expect(manager.save).toHaveBeenCalledOnce();
  });
});
