import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const swagger = new DocumentBuilder().setTitle('DACN API').setVersion('1.0').addBearerAuth().build();
  SwaggerModule.setup('api', app, SwaggerModule.createDocument(app, swagger));
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
await bootstrap();
