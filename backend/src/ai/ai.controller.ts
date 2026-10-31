import { Body, Controller, Get, HttpCode, Param, ParseIntPipe, Post, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser, Roles } from '../auth/auth.decorators.js';
import { AiService } from './ai.service.js';

interface UploadedImage { buffer: Buffer; mimetype: string; originalname?: string; }

@ApiTags('ai')
@ApiBearerAuth()
@Controller('ai')
export class AiController {
  constructor(private readonly ai: AiService) {}

  @Post('diagnose-image') @ApiConsumes('multipart/form-data') @UseInterceptors(FileInterceptor('image', { limits: { fileSize: 2 * 1024 * 1024 } }))
  diagnose(@UploadedFile() image: UploadedImage) { return this.ai.diagnose(image as never); }

  @Post('chat') @HttpCode(200)
  chat(@Body('symptoms') symptoms: string) { return this.ai.chat(symptoms); }

  @Roles('patient') @Post('report') @ApiConsumes('multipart/form-data') @UseInterceptors(FileInterceptor('image', { limits: { fileSize: 2 * 1024 * 1024 } }))
  async report(@CurrentUser() user: { patientId: number }, @UploadedFile() image: UploadedImage | undefined, @Body('symptoms') symptoms: string, @Body('appointmentId') appointmentId: string | undefined, @Res() response: Response) {
    const pdf = await this.ai.report(user.patientId, image as never, symptoms ?? '', appointmentId ? Number(appointmentId) : undefined);
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': 'attachment; filename="ai-report.pdf"', 'Content-Length': String(pdf.length) });
    response.end(pdf);
  }

  @Roles('doctor') @Get('report/:appointmentId')
  async doctorReport(@CurrentUser() user: { doctorId: number }, @Param('appointmentId', ParseIntPipe) id: number, @Res() response: Response) {
    const pdf = await this.ai.getReport(id, user.doctorId);
    if (!pdf) return response.status(404).end();
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': `attachment; filename="report-${id}.pdf"` });
    response.end(pdf);
  }
}
