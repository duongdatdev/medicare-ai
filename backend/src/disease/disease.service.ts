import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { CreateDiseaseDto, UpdateDiseaseDto } from './disease.dto.js';
import { Disease } from './disease.entity.js';

@Injectable()
export class DiseaseService {
  constructor(@InjectRepository(Disease) private readonly diseases: Repository<Disease>, private readonly config: ConfigService) {}

  async list(role: string) {
    const items = await this.diseases.find({ where: role === 'doctor' ? { active: true } : {}, order: { name: 'ASC' } });
    return {
      examFee: Number(this.config.get('EXAM_FEE', 50000)),
      examFeeBhytCovered: this.config.get('EXAM_FEE_BHYT_COVERED') !== 'false',
      items,
    };
  }

  async create(input: CreateDiseaseDto) {
    try {
      return await this.diseases.save(this.diseases.create({ ...input, active: true, bhytCovered: input.bhytCovered ?? true }));
    } catch (error) {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { driverError?: { code?: string } }).driverError?.code === '23505') {
        throw new ConflictException('Tên bệnh đã tồn tại');
      }
      throw error;
    }
  }

  async update(id: number, changes: UpdateDiseaseDto) {
    const disease = await this.diseases.findOneBy({ id });
    if (!disease) throw new NotFoundException();
    return this.diseases.save(Object.assign(disease, changes));
  }
}
