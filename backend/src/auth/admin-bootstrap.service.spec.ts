import { describe, expect, it, vi } from 'vitest';
import { AdminBootstrapService } from './admin-bootstrap.service.js';

describe('AdminBootstrapService', () => {
  it('creates a login-compatible admin only when bootstrap credentials are configured', async () => {
    const config = { get: (key: string) => ({ BOOTSTRAP_ADMIN_EMAIL: 'admin@example.test', BOOTSTRAP_ADMIN_PASSWORD: 'local-password-123' })[key] };
    const accounts = { existsBy: vi.fn().mockResolvedValue(false), create: vi.fn((account) => account), save: vi.fn(async (account) => account) };
    const service = new AdminBootstrapService(config as never, accounts as never);

    await service.onApplicationBootstrap();

    expect(accounts.save).toHaveBeenCalledWith(expect.objectContaining({ email: 'admin@example.test', role: 'admin', patientId: null, doctorId: null }));
    expect(accounts.save.mock.calls[0][0].passwordHash).not.toBe('local-password-123');
  });
});
