import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BhytRegistry } from './bhyt-registry.entity.js';
import { maskCardNumber, rateFromCard } from './billing.util.js';

@Injectable()
export class BhytService {
  constructor(@InjectRepository(BhytRegistry) private readonly registry: Repository<BhytRegistry>) {}

  async lookup(cccd: string, birthDate: string) {
    const card = await this.registry.findOneBy({ cccd, birthDate });
    if (!card) return { found: false };
    return {
      found: true,
      cardNumber: maskCardNumber(card.cardNumber),
      rate: rateFromCard(card.cardNumber),
      validTo: card.validTo,
      status: card.validTo < new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }) ? 'expired' : 'valid',
    };
  }
}
