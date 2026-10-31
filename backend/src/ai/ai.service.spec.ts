import { ForbiddenException } from '@nestjs/common';
import { describe, expect, it, vi } from 'vitest';
import { AiService } from './ai.service.js';

describe('AI report access', () => {
  it('rejects a patient attaching a report to another patient appointment', async () => {
    const appointments = { findOneBy: vi.fn().mockResolvedValue({ id: 7, patientId: 22 }) };
    const service = new AiService({ get: () => 'http://localhost:8000' } as never, appointments as never, {} as never);

    await expect(service.report(23, undefined, 'symptoms', 7)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('checks doctor ownership before returning a stored PDF', async () => {
    const appointments = { findOneBy: vi.fn().mockResolvedValue({ id: 7, doctorId: 10 }) };
    const service = new AiService({ get: () => 'http://localhost:8000' } as never, appointments as never, {} as never);

    await expect(service.getReport(7, 11)).rejects.toBeInstanceOf(ForbiddenException);
  });
});
