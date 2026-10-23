import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        host: config.get<string>('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USER', 'postgres'),
        password: config.get<string>('DB_PASSWORD', 'postgres'),
        database: config.get<string>('DB_NAME', 'dacn_dev'),
        autoLoadEntities: true,
        synchronize: false,
        migrationsRun: true,
        migrations: [import.meta.dirname + '/migrations/*{.ts,.js}'],
        extra: { options: '-c timezone=Asia/Ho_Chi_Minh' },
      }),
    }),
  ],
})
export class DatabaseModule {}
