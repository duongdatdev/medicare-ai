import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMedicalReports1760700000000 implements MigrationInterface {
  name = 'AddMedicalReports1760700000000';
  async up(query: QueryRunner): Promise<void> {
    await query.query(`CREATE TABLE "medical_report" (
      "id" SERIAL PRIMARY KEY, "appointmentId" integer NOT NULL REFERENCES "appointment"("id") ON DELETE CASCADE,
      "pdf" bytea NOT NULL, "createdAt" timestamp NOT NULL DEFAULT now()
    )`);
  }
  async down(query: QueryRunner): Promise<void> { await query.query('DROP TABLE "medical_report"'); }
}
