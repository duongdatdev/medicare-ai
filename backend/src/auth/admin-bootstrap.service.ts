import { Injectable, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import { Account } from './account.entity.js';

@Injectable()
export class AdminBootstrapService implements OnApplicationBootstrap {
  constructor(private readonly config: ConfigService, @InjectRepository(Account) private readonly accounts: Repository<Account>) {}

  async onApplicationBootstrap() {
    const email = this.config.get<string>('BOOTSTRAP_ADMIN_EMAIL');
    const password = this.config.get<string>('BOOTSTRAP_ADMIN_PASSWORD');
    if (!email && !password) return;
    if (!email || !password || password.length < 12) throw new Error('Set both bootstrap admin credentials and use at least 12 password characters');
    if (await this.accounts.existsBy({ email })) return;
    await this.accounts.save(this.accounts.create({
      email, passwordHash: await bcrypt.hash(password, 10), role: 'admin', patientId: null, doctorId: null,
    }));
  }
}
