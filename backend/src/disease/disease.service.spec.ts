import { describe, expect, it, vi } from 'vitest';
import { DiseaseService } from './disease.service.js';

describe('DiseaseService role-specific price list', () => {
  it('returns active items for doctors and the complete catalog for admins', async () => {
    const diseases = { find: vi.fn().mockResolvedValue([]) };
    const config = { get: (key: string, fallback: unknown) => fallback };
    const service = new DiseaseService(diseases as never, config as never);

    await expect(service.list('doctor')).resolves.toEqual({ examFee: 50000, examFeeBhytCovered: true, items: [] });
    expect(diseases.find).toHaveBeenLastCalledWith({ where: { active: true }, order: { name: 'ASC' } });
    await service.list('admin');
    expect(diseases.find).toHaveBeenLastCalledWith({ where: {}, order: { name: 'ASC' } });
  });
});
