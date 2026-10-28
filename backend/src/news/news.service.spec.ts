import { describe, expect, it, vi } from 'vitest';
import { NewsService } from './news.service.js';

describe('NewsService', () => {
  it('clamps the list size to the supported 1–50 range', async () => {
    const news = { find: vi.fn().mockResolvedValue([]) };
    const service = new NewsService(news as never);

    await service.list(500);
    expect(news.find).toHaveBeenCalledWith({ order: { createdAt: 'DESC' }, take: 50 });
    await service.list(-10);
    expect(news.find).toHaveBeenLastCalledWith({ order: { createdAt: 'DESC' }, take: 1 });
  });
});
