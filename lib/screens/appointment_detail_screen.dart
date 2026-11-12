import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/appointment.dart';
import '../services/ai_reports.dart';
import '../services/appointments.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';
import 'ai_report_screen.dart';
import 'payment_screen.dart';
import 're_examination_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    required this.appointment,
    required this.doctor,
    super.key,
  });

  final Appointment appointment;
  final bool doctor;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Future<Map<String, dynamic>> _detail;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  List<String> _slots = [];
  bool _loadingSlots = false;
  bool _saving = false;
  bool _loadingReport = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _detail = Appointments().detail(
      widget.appointment.id,
      doctor: widget.doctor,
    );
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || widget.appointment.doctorId == null) return;
    setState(() {
      _date = date;
      _loadingSlots = true;
      _slots = [];
    });
    try {
      _slots = await Appointments().availability(
        widget.appointment.doctorId!,
        _date,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  Future<void> _reschedule(String slot) async {
    setState(() => _saving = true);
    try {
      await Appointments().reschedule(
        widget.appointment.id,
        slot,
        doctor: widget.doctor,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDoctorReport() async {
    setState(() => _loadingReport = true);
    try {
      final bytes = await AiReports().doctorReport(widget.appointment.id);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'report-${widget.appointment.id}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loadingReport = false);
    }
  }

  (String, BadgeTone) _statusMeta(int status, String? cancelReason) {
    if (cancelReason != null && cancelReason.trim().isNotEmpty) {
      return ('Đã hủy', BadgeTone.danger);
    }
    return switch (status) {
      0 => ('Đã xác nhận', BadgeTone.success),
      2 => ('Đã khám xong', BadgeTone.info),
      _ => ('Chờ xác nhận', BadgeTone.warning),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Chi tiết lịch #${widget.appointment.id}')),
    body: ResponsiveCenter(
      maxWidth: 740,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message:
                  'Không tải được chi tiết: ${formatApiError(snapshot.error!)}',
              onRetry: () => setState(_load),
            );
          }

          final detail = snapshot.data ?? const <String, dynamic>{};
          final relation = detail[widget.doctor ? 'patient' : 'doctor'];
          final relationMap = relation is Map<String, dynamic>
              ? relation
              : null;
          final relationName = relationMap?['name'];
          final otherParty =
              [
                    widget.appointment.name,
                    detail[widget.doctor ? 'patientName' : 'doctorName'],
                    relationName,
                  ]
                  .whereType<String>()
                  .map((name) => name.trim())
                  .firstWhere((name) => name.isNotEmpty, orElse: () => '—');

          final rawTime = detail['apTime'];
          final appointmentTime = rawTime is String
              ? DateTime.tryParse(rawTime)
              : widget.appointment.time;
          final displayTime = formatDateTime(appointmentTime, fallback: '—');
          final status =
              (detail['confirmCondition'] as num?)?.toInt() ??
              widget.appointment.status;
          final cancelReason =
              detail['cancelReason'] as String? ??
              widget.appointment.cancelReason;
          final rescheduled =
              detail['rescheduled'] as bool? ?? widget.appointment.rescheduled;
          final (statusLabel, statusTone) = _statusMeta(status, cancelReason);

          final mayReschedule =
              (widget.doctor ? status == 0 : status != 2) &&
              !rescheduled &&
              cancelReason == null;

          final items =
              (detail['items'] as List<dynamic>?)
                  ?.whereType<Map<String, dynamic>>()
                  .toList() ??
              const <Map<String, dynamic>>[];
          final hasBill = detail['total'] != null || items.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            imagePath:
                                relationMap?['avatar'] as String? ??
                                widget.appointment.avatar,
                            name: otherParty,
                            radius: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherParty,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  widget.doctor ? 'Bệnh nhân' : 'Bác sĩ khám',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: statusLabel, tone: statusTone),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 8),
                      KeyValueRow(
                        icon: Icons.schedule_outlined,
                        label: 'Thời gian',
                        value: displayTime,
                      ),
                      KeyValueRow(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ',
                        value:
                            '${detail['address'] ?? widget.appointment.address}',
                      ),
                      KeyValueRow(
                        icon: Icons.notes_outlined,
                        label: 'Ghi chú',
                        value:
                            '${detail['doctorNote'] ?? detail['note'] ?? widget.appointment.note ?? '—'}',
                      ),
                      if (rescheduled)
                        const KeyValueRow(
                          icon: Icons.event_repeat_outlined,
                          label: 'Trạng thái đổi lịch',
                          value: 'Đã đổi lịch 1 lần',
                        ),
                    ],
                  ),
                ),
              ),
              if (cancelReason != null && cancelReason.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                ClinicBanner(
                  message: 'Lý do hủy: $cancelReason',
                  tone: BadgeTone.danger,
                ),
              ],
              if (hasBill) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: SectionHeader(
                                title: 'Chi tiết chẩn đoán & hóa đơn',
                              ),
                            ),
                            if (detail['paymentStatus'] != null)
                              StatusBadge(
                                label: paymentStatusLabel(
                                  detail['paymentStatus'] as String?,
                                ),
                                tone: detail['paymentStatus'] == 'paid'
                                    ? BadgeTone.success
                                    : detail['paymentStatus'] == 'pending'
                                    ? BadgeTone.warning
                                    : BadgeTone.danger,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (detail['examFee'] != null)
                          KeyValueRow(
                            label: 'Phí khám bệnh',
                            value: formatVnd(detail['examFee']),
                          ),
                        for (final item in items)
                          KeyValueRow(
                            label:
                                '${item['name']} ${item['bhytCovered'] == true ? '(BHYT)' : '(Tự chi trả)'}',
                            value: formatVnd(item['price']),
                          ),
                        const Divider(),
                        if (detail['total'] != null)
                          KeyValueRow(
                            label: 'Tổng chi phí',
                            value: formatVnd(detail['total']),
                          ),
                        if (detail['insuranceCovered'] != null)
                          KeyValueRow(
                            label: 'BHYT chi trả',
                            value: '-${formatVnd(detail['insuranceCovered'])}',
                            valueColor: AppColors.successFg,
                          ),
                        if (detail['payable'] != null)
                          KeyValueRow(
                            label: 'Cần thanh toán',
                            value: formatVnd(detail['payable']),
                            bold: true,
                            valueColor: AppColors.primaryDark,
                          ),
                        if (!widget.doctor && status == 2) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    appointmentId: widget.appointment.id,
                                  ),
                                ),
                              ).then((_) => setState(_load)),
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('Xem hóa đơn / thanh toán'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (mayReschedule) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Đổi lịch khám',
                          subtitle: 'Mỗi lịch hẹn hỗ trợ đổi tối đa 1 lần',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _chooseDate,
                            icon: const Icon(Icons.event_repeat),
                            label: const Text('Chọn ngày đổi lịch'),
                          ),
                        ),
                        if (_loadingSlots) ...[
                          const SizedBox(height: 14),
                          const Center(child: CircularProgressIndicator()),
                        ] else if (_slots.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final slot in _slots)
                                ActionChip(
                                  label: Text(
                                    formatDateTime(DateTime.parse(slot)),
                                  ),
                                  onPressed: _saving
                                      ? null
                                      : () => _reschedule(slot),
                                ),
                            ],
                          ),
                        ],
                        if (widget.appointment.doctorId == null) ...[
                          const SizedBox(height: 10),
                          const ClinicBanner(
                            message:
                                'Lịch này chưa có mã bác sĩ để tra khung giờ trống.',
                            tone: BadgeTone.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if ((!widget.doctor && status != 2 && cancelReason == null) ||
                  (widget.doctor && cancelReason == null)) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Hỗ trợ AI & Tái khám',
                          subtitle:
                              'Phân tích hình ảnh, triệu chứng và tài liệu trước khám',
                        ),
                        const SizedBox(height: 12),
                        if (!widget.doctor &&
                            status != 2 &&
                            cancelReason == null)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiReportScreen(
                                    appointment: widget.appointment,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.smart_toy_outlined),
                              label: const Text(
                                'Gửi ảnh và triệu chứng cho AI',
                              ),
                            ),
                          ),
                        if (widget.doctor && cancelReason == null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loadingReport
                                  ? null
                                  : _openDoctorReport,
                              icon: _loadingReport
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: const Text('Mở báo cáo AI của bệnh nhân'),
                            ),
                          ),
                        if (widget.doctor &&
                            status == 2 &&
                            widget.appointment.patientId != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () =>
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReExaminationScreen(
                                        patientId:
                                            widget.appointment.patientId!,
                                      ),
                                    ),
                                  ).then((created) {
                                    if (created == true && context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  }),
                              icon: const Icon(Icons.event_repeat),
                              label: const Text('Đặt lịch tái khám'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
