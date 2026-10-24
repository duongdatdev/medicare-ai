import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateDiseaseCatalog1760200000000 implements MigrationInterface {
  name = 'CreateDiseaseCatalog1760200000000';

  async up(query: QueryRunner): Promise<void> {
    await query.query(`CREATE TABLE "disease" (
      "id" SERIAL PRIMARY KEY, "name" varchar NOT NULL UNIQUE,
      "price" integer NOT NULL CHECK ("price" >= 0),
      "active" boolean NOT NULL DEFAULT true, "bhytCovered" boolean NOT NULL DEFAULT true
    )`);
  }

  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "disease"');
  }
}
