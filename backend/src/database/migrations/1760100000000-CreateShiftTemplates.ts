import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateShiftTemplates1760100000000 implements MigrationInterface {
  name = 'CreateShiftTemplates1760100000000';

  async up(query: QueryRunner): Promise<void> {
    await query.query(`CREATE TABLE "shift" (
      "id" SERIAL PRIMARY KEY, "type" varchar NOT NULL UNIQUE,
      "startTime" time NOT NULL, "endTime" time NOT NULL
    )`);
    await query.query(`INSERT INTO "shift" ("type", "startTime", "endTime") VALUES
      ('morning', '07:00', '11:00'), ('afternoon', '13:00', '17:00'), ('evening', '17:00', '21:00')`);
    await query.query(`CREATE TABLE "shiftAssignment" (
      "id" SERIAL PRIMARY KEY, "type" varchar NOT NULL,
      "startTime" timestamp NOT NULL, "endTime" timestamp NOT NULL,
      "status" varchar NOT NULL DEFAULT 'ACTIVE', "duration" double precision NOT NULL DEFAULT 0,
      "doctorId" integer NOT NULL REFERENCES "doctor"("id"),
      "shiftId" integer NOT NULL REFERENCES "shift"("id"), UNIQUE("doctorId", "startTime", "shiftId")
    )`);
  }

  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "shiftAssignment"');
    await query.query('DROP TABLE "shift"');
  }
}
