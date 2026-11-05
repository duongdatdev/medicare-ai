import { describe, expect, it, vi } from 'vitest';
import { validate } from 'class-validator';
import { CreateNewsDto } from './news.dto.js';
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

  it('rejects empty titles and URLs without http(s) schemes', async () => {
    const input = Object.assign(new CreateNewsDto(), { title: '', url: 'clinic.local/article' });

    const errors = await validate(input);

    expect(errors.map(({ property }) => property)).toEqual(expect.arrayContaining(['title', 'url']));
  });
});
