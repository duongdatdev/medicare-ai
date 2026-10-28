import { describe, expect, it, vi } from 'vitest';
import { BhytService } from './bhyt.service.js';

describe('BHYT pre-registration lookup', () => {
  it('returns no identifying card data when the CCCD and birth date do not match', async () => {
    const registry = { findOneBy: vi.fn().mockResolvedValue(null) };
    const service = new BhytService(registry as never);
    await expect(service.lookup('079203000001', '2000-01-01')).resolves.toEqual({ found: false });
    expect(registry.findOneBy).toHaveBeenCalledWith({ cccd: '079203000001', birthDate: '2000-01-01' });
  });

  it('returns a masked card with coverage level on a match', async () => {
    const registry = { findOneBy: vi.fn().mockResolvedValue({ cardNumber: 'DN3490123456789', validTo: '2099-01-01' }) };
    const service = new BhytService(registry as never);
    await expect(service.lookup('079203000001', '2000-01-01')).resolves.toEqual({
      found: true, cardNumber: 'DN3********6789', rate: 0.95, validTo: '2099-01-01', status: 'valid',
    });
  });
});
