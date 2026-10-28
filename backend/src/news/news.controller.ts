import { BadRequestException, Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query, UploadedFile, UseInterceptors } from '@nestjs/common';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { Roles } from '../auth/auth.decorators.js';
import { CreateNewsDto } from './news.dto.js';
import { NewsService } from './news.service.js';

interface UploadedImage {
  buffer: Buffer;
  mimetype: string;
}

@ApiTags('news')
@ApiBearerAuth()
@Controller('news')
export class NewsController {
  constructor(private readonly news: NewsService) {}

  @Get() list(@Query('limit') limit?: string) { return this.news.list(Number(limit) || 50); }

  @Roles('admin')
  @Post()
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('image', { limits: { fileSize: 2 * 1024 * 1024 }, fileFilter: (_request, file, callback) => {
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) return callback(new BadRequestException('Ảnh không hợp lệ'), false);
    callback(null, true);
  } }))
  create(@Body() input: CreateNewsDto, @UploadedFile() image?: UploadedImage) {
    if (!image) throw new BadRequestException('Ảnh tin tức là bắt buộc');
    return this.news.create(input, image);
  }

  @Roles('admin')
  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) { return this.news.remove(id); }
}
