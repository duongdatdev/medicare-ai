import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateBhytRegistry1760500000000 implements MigrationInterface {
  name = 'CreateBhytRegistry1760500000000';
  async up(query: QueryRunner): Promise<void> {
    await query.query(`ALTER TABLE "patient" ADD COLUMN "insuranceNumber" varchar(15)`);
    await query.query(`ALTER TABLE "patient" ADD COLUMN "insuranceValidFrom" date`);
    await query.query(`ALTER TABLE "patient" ADD COLUMN "insuranceValidTo" date`);
    await query.query(`CREATE TABLE "bhyt_registry" (
      "id" SERIAL PRIMARY KEY, "cccd" varchar(12) NOT NULL UNIQUE,
      "cardNumber" varchar(15) NOT NULL UNIQUE, "fullName" varchar NOT NULL,
      "birthDate" date NOT NULL, "validFrom" date NOT NULL, "validTo" date NOT NULL
    )`);
  }
  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "bhyt_registry"');
    await query.query(`ALTER TABLE "patient" DROP COLUMN "insuranceValidTo", DROP COLUMN "insuranceValidFrom", DROP COLUMN "insuranceNumber"`);
  }
}
