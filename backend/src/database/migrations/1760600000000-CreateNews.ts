import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateNews1760600000000 implements MigrationInterface {
  name = 'CreateNews1760600000000';
  async up(query: QueryRunner): Promise<void> {
    await query.query(`CREATE TABLE "news" (
      "id" SERIAL PRIMARY KEY, "title" varchar(200) NOT NULL,
      "url" varchar(2000) NOT NULL, "imagePath" varchar NOT NULL,
      "createdAt" timestamp NOT NULL DEFAULT now()
    )`);
  }
  async down(query: QueryRunner): Promise<void> { await query.query('DROP TABLE "news"'); }
}
