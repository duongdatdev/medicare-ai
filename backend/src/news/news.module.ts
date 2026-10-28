import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NewsController } from './news.controller.js';
import { News } from './news.entity.js';
import { NewsService } from './news.service.js';

@Module({ imports: [TypeOrmModule.forFeature([News])], controllers: [NewsController], providers: [NewsService] })
export class NewsModule {}
