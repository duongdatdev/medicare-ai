import { Body, Controller, Get, Headers, HttpCode, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Public, Roles } from '../auth/auth.decorators.js';
import { PayAppointmentDto, SepayWebhookDto } from './payment.dto.js';
import { PaymentService } from './payment.service.js';

@ApiTags('payment')
@ApiBearerAuth()
@Controller()
export class PaymentController {
  constructor(private readonly payments: PaymentService) {}

  @Roles('patient')
  @Post('patient/appointment/:id/pay')
  pay(@CurrentUser() user: { patientId: number }, @Param('id', ParseIntPipe) id: number, @Body() input: PayAppointmentDto) {
    return this.payments.pay(user.patientId, id, input);
  }

  @Public()
  @Post('payments/sepay-webhook')
  @HttpCode(200)
  webhook(@Headers('authorization') auth: string | undefined, @Body() input: SepayWebhookDto) {
    this.payments.assertWebhookKey(auth);
    return this.payments.handleWebhook(input);
  }

  @Roles('admin')
  @Get('admin/payments') pending() { return this.payments.pendingPayments(); }

  @Roles('admin')
  @Post('admin/payments/:id/confirm')
  confirm(@CurrentUser() user: { sub: number }, @Param('id', ParseIntPipe) id: number) { return this.payments.confirm(user.sub, id); }

  @Roles('admin')
  @Get('admin/notifications') notifications() { return this.payments.notificationsList(); }

  @Roles('admin')
  @Get('admin/notifications/unread-count') unread() { return this.payments.unreadCount(); }

  @Roles('admin')
  @Post('admin/notifications/read-all') readAll() { return this.payments.readAll(); }
}
