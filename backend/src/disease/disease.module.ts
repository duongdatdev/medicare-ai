import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DiseaseController } from './disease.controller.js';
import { Disease } from './disease.entity.js';
import { DiseaseService } from './disease.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Disease])],
  controllers: [DiseaseController],
  providers: [DiseaseService],
})
export class DiseaseModule {}
