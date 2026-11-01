import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddInvoiceSnapshots1760300000000 implements MigrationInterface {
  name = 'AddInvoiceSnapshots1760300000000';

  async up(query: QueryRunner): Promise<void> {
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "examFee" integer`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "total" integer`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "insuranceRate" real`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "insuranceCovered" integer`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "payable" integer`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "examFeeCovered" boolean`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "insuranceCardNumber" varchar(15)`);
    await query.query(`CREATE TABLE "appointment_item" (
      "id" SERIAL PRIMARY KEY, "name" varchar(200) NOT NULL, "price" integer NOT NULL,
      "bhytCovered" boolean NOT NULL DEFAULT true, "appointmentId" integer NOT NULL
      REFERENCES "appointment"("id") ON DELETE CASCADE
    )`);
  }

  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "appointment_item"');
    await query.query(`ALTER TABLE "appointment" DROP COLUMN "insuranceCardNumber", DROP COLUMN "examFeeCovered", DROP COLUMN "payable", DROP COLUMN "insuranceCovered", DROP COLUMN "insuranceRate", DROP COLUMN "total", DROP COLUMN "examFee"`);
  }
}
