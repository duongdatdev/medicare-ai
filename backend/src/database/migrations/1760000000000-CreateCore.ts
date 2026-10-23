import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateCore1760000000000 implements MigrationInterface {
  name = 'CreateCore1760000000000';

  async up(query: QueryRunner): Promise<void> {
    await query.query(`CREATE TABLE "patient" (
      "id" SERIAL PRIMARY KEY, "name" varchar NOT NULL, "gender" varchar NOT NULL,
      "age" integer NOT NULL, "birthDate" date NOT NULL, "email" varchar NOT NULL,
      "phone" varchar NOT NULL, "address" varchar NOT NULL, "createAt" timestamp NOT NULL DEFAULT now(),
      "avatar" varchar NOT NULL DEFAULT '', "cccd" varchar(12) UNIQUE NOT NULL
    )`);
    await query.query(`CREATE TABLE "doctor" (
      "id" SERIAL PRIMARY KEY, "name" varchar NOT NULL, "age" integer NOT NULL,
      "dateOfBirth" timestamp NOT NULL, "gender" varchar NOT NULL, "phone" varchar NOT NULL,
      "address" varchar NOT NULL, "email" varchar NOT NULL UNIQUE, "avatar" varchar NOT NULL DEFAULT ''
    )`);
    await query.query(`CREATE TABLE "account" (
      "id" SERIAL PRIMARY KEY, "email" varchar NOT NULL UNIQUE, "passwordHash" varchar NOT NULL,
      "role" varchar NOT NULL, "patientId" integer UNIQUE REFERENCES "patient"("id"),
      "doctorId" integer UNIQUE REFERENCES "doctor"("id"), "createdAt" timestamp NOT NULL DEFAULT now()
    )`);
    await query.query(`CREATE TABLE "appointment" (
      "id" SERIAL PRIMARY KEY, "apTime" timestamp NOT NULL, "confirmDate" timestamp,
      "address" varchar NOT NULL, "note" text, "doctorNote" text, "confirmCondition" integer NOT NULL DEFAULT 1,
      "cancelReason" text, "canceledBy" varchar, "rescheduled" boolean NOT NULL DEFAULT false,
      "doctorName" varchar NOT NULL, "patientId" integer NOT NULL REFERENCES "patient"("id"),
      "doctorId" integer NOT NULL REFERENCES "doctor"("id"), UNIQUE("doctorId", "apTime")
    )`);
  }

  async down(query: QueryRunner): Promise<void> {
    await query.query('DROP TABLE "appointment"');
    await query.query('DROP TABLE "account"');
    await query.query('DROP TABLE "doctor"');
    await query.query('DROP TABLE "patient"');
  }
}
