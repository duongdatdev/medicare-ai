import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPayments1760400000000 implements MigrationInterface {
  name = 'AddPayments1760400000000';
  async up(query: QueryRunner): Promise<void> {
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "paymentMethod" varchar`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "paymentStatus" varchar NOT NULL DEFAULT 'unpaid'`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "paidAt" timestamp`);
    await query.query(`ALTER TABLE "appointment" ADD COLUMN "paidBy" integer`);
    await query.query(`CREATE TABLE "notification" (
      "id" SERIAL PRIMARY KEY, "title" varchar NOT NULL, "body" text NOT NULL,
      "createdAt" timestamp NOT NULL DEFAULT now(), "readAt" timestamp, "appointmentId" integer
    )`);
  }
  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "notification"');
    await query.query(`ALTER TABLE "appointment" DROP COLUMN "paidBy", DROP COLUMN "paidAt", DROP COLUMN "paymentStatus", DROP COLUMN "paymentMethod"`);
  }
}
