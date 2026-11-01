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

  async findCard(cccd: string, birthDate: string) {
    return this.registry.findOneBy({ cccd, birthDate });
  }

  static describe(card: BhytRegistry | null) {
    if (!card) return null;
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' });
    const status = today < card.validFrom ? 'not_yet_valid' : today > card.validTo ? 'expired' : 'valid';
    return { cardNumber: card.cardNumber, validFrom: card.validFrom, validTo: card.validTo, rate: rateFromCard(card.cardNumber), status };
  }
}
