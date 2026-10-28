import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomUUID } from 'node:crypto';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { CreateNewsDto } from './news.dto.js';
import { News } from './news.entity.js';

interface UploadedImage {
  buffer: Buffer;
  mimetype: string;
}

@Injectable()
export class NewsService {
  constructor(@InjectRepository(News) private readonly news: Repository<News>) {}

  list(limit = 50) {
    return this.news.find({ order: { createdAt: 'DESC' }, take: Math.min(50, Math.max(1, limit)) });
  }

  async create(input: CreateNewsDto, image: UploadedImage) {
    const extension = image.mimetype === 'image/png' ? '.png' : image.mimetype === 'image/webp' ? '.webp' : '.jpg';
    const filename = `${randomUUID()}${extension}`;
    const directory = join(process.cwd(), 'uploads', 'news');
    await mkdir(directory, { recursive: true });
    await writeFile(join(directory, filename), image.buffer, { flag: 'wx' });
    try {
      return await this.news.save(this.news.create({ ...input, imagePath: `/uploads/news/${filename}` }));
    } catch (error) {
      await rm(join(directory, filename), { force: true });
      throw error;
    }
  }

  async remove(id: number) {
    const item = await this.news.findOneBy({ id });
    if (!item) throw new NotFoundException();
    await this.news.remove(item);
    if (item.imagePath.startsWith('/uploads/news/')) {
      await rm(join(process.cwd(), item.imagePath.replace(/^\//, '')), { force: true });
    }
    return { ok: true };
  }
}
