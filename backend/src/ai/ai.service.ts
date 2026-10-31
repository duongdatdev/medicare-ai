import { ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import PDFDocument from 'pdfkit';
import { Repository } from 'typeorm';
import { Appointment } from '../patient/appointment.entity.js';
import { MedicalReport } from '../patient/medical-report.entity.js';

interface UploadedImage { buffer: Buffer; mimetype: string; originalname?: string; }

@Injectable()
export class AiService {
  private readonly baseUrl: string;
  constructor(config: ConfigService, @InjectRepository(Appointment) private readonly appointments: Repository<Appointment>, @InjectRepository(MedicalReport) private readonly reports: Repository<MedicalReport>) {
    this.baseUrl = config.get<string>('AI_SERVICE_URL', 'http://localhost:8000');
  }

  async diagnose(image: UploadedImage) {
    if (!image) throw new HttpException('Image is required', 400);
    const form = new FormData();
    form.append('file', new Blob([image.buffer], { type: image.mimetype }), image.originalname || 'upload.jpg');
    return this.forward('/predict', { method: 'POST', body: form });
  }

  chat(symptoms: string) {
    return this.forward('/chat', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ symptoms }) });
  }

  async report(patientId: number, image: UploadedImage | undefined, symptoms: string, appointmentId?: number) {
    if (appointmentId) {
      const appointment = await this.appointments.findOneBy({ id: appointmentId });
      if (!appointment) throw new NotFoundException();
      if (appointment.patientId !== patientId) throw new ForbiddenException();
    }
    const imageResult = image ? await this.diagnose(image) as { results?: { disease: string; confidence?: number }[] } : undefined;
    const chatResult = symptoms.trim() ? await this.chat(symptoms) as { results?: { disease: string; confidence?: number; reason?: string }[] } : undefined;
    const pdf = await this.renderPdf(symptoms, imageResult?.results ?? [], chatResult?.results ?? []);
    if (appointmentId) await this.reports.save(this.reports.create({ pdf, appointment: { id: appointmentId } as Appointment }));
    return pdf;
  }

  async getReport(appointmentId: number, doctorId?: number) {
    if (doctorId !== undefined) {
      const appointment = await this.appointments.findOneBy({ id: appointmentId });
      if (!appointment) throw new NotFoundException();
      if (appointment.doctorId !== doctorId) throw new ForbiddenException();
    }
    const report = await this.reports.findOne({ where: { appointment: { id: appointmentId } }, order: { createdAt: 'DESC' } });
    return report?.pdf ?? null;
  }

  private async forward(path: string, init: RequestInit) {
    let response: Response;
    try { response = await fetch(`${this.baseUrl}${path}`, init); }
    catch { throw new ServiceUnavailableException(`AI service unavailable at ${this.baseUrl}`); }
    const body = await response.text();
    if (!response.ok) throw new HttpException(body || 'AI service error', response.status);
    try { return JSON.parse(body); } catch { return { raw: body }; }
  }

  private renderPdf(symptoms: string, image: { disease: string; confidence?: number }[], chat: { disease: string; confidence?: number; reason?: string }[]) {
    return new Promise<Buffer>((resolve, reject) => {
      const document = new PDFDocument({ margin: 48 });
      const parts: Buffer[] = [];
      document.on('data', (part: Buffer) => parts.push(part));
      document.on('end', () => resolve(Buffer.concat(parts)));
      document.on('error', reject);
      document.fontSize(18).text('Preliminary AI health report', { align: 'center' }).moveDown();
      document.fontSize(11).text(`Symptoms: ${symptoms || 'Not provided'}`).moveDown();
      for (const [heading, results] of [['Image analysis', image], ['Symptom analysis', chat]] as const) {
        document.fontSize(13).text(heading);
      for (const result of results) document.fontSize(10).text(`${result.disease}${result.confidence === undefined ? '' : ` — ${(result.confidence * 100).toFixed(1)}%`}${'reason' in result && result.reason ? ` — ${result.reason}` : ''}`);
        document.moveDown();
      }
      document.fontSize(9).text('AI results are informational and do not replace medical advice.');
      document.end();
    });
  }
}
