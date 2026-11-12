import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointments.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';
import 'appointment_detail_screen.dart';
import 'complete_appointment_dialog.dart';
import 'payment_screen.dart';

enum _PatientFilter { all, pending, confirmed, completed, canceled }

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({required this.doctor, super.key});
  final bool doctor;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _service = Appointments();
  late Future<List<Appointment>> _items;
  int _doctorStatus = 1;
  _PatientFilter _patientFilter = _PatientFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = widget.doctor
        ? _service.doctorList(_doctorStatus)
        : _service.patientList();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _items;
  }

  List<Appointment> _applyPatientFilter(List<Appointment> source) {
    return switch (_patientFilter) {
      _PatientFilter.all => source,
      _PatientFilter.pending =>
        source.where((a) => !a.isCanceled && a.status == 1).toList(),
      _PatientFilter.confirmed =>
        source.where((a) => !a.isCanceled && a.status == 0).toList(),
      _PatientFilter.completed =>
        source.where((a) => !a.isCanceled && a.status == 2).toList(),
      _PatientFilter.canceled => source.where((a) => a.isCanceled).toList(),
    };
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.doctor)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Chờ')),
              ButtonSegment(value: 0, label: Text('Đã xác nhận')),
              ButtonSegment(value: 2, label: Text('Đã khám')),
            ],
            selected: {_doctorStatus},
            onSelectionChanged: (value) => setState(() {
              _doctorStatus = value.first;
              _reload();
            }),
          ),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final (filter, label) in const [
                (_PatientFilter.all, 'Tất cả'),
                (_PatientFilter.pending, 'Chờ xác nhận'),
                (_PatientFilter.confirmed, 'Đã xác nhận'),
                (_PatientFilter.completed, 'Đã khám'),
                (_PatientFilter.canceled, 'Đã hủy'),
              ]) ...[
                FilterChip(
                  label: Text(label),
                  selected: _patientFilter == filter,
                  onSelected: (_) => setState(() => _patientFilter = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      Expanded(
        child: FutureBuilder<List<Appointment>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Không tải được danh sách lịch hẹn',
                onRetry: () => setState(_reload),
              );
            }
            final allItems = snapshot.data ?? [];
            final items = widget.doctor
                ? allItems
                : _applyPatientFilter(allItems);

            if (items.isEmpty) {
              return EmptyStateView(
                icon: Icons.event_note_outlined,
                title: 'Chưa có lịch hẹn',
                subtitle: widget.doctor
                    ? 'Danh sách lịch hẹn thuộc mục này hiện đang trống.'
                    : 'Nhấn "Đặt lịch" để chọn bác sĩ và khung giờ phù hợp.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _AppointmentCard(
                  appointment: items[index],
                  doctor: widget.doctor,
                  refresh: () => setState(_reload),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.doctor,
    required this.refresh,
  });

  final Appointment appointment;
  final bool doctor;
  final VoidCallback refresh;

  (String, BadgeTone) get _statusMeta {
    if (appointment.isCanceled) return ('Đã hủy', BadgeTone.danger);
    return switch (appointment.status) {
      0 => ('Đã xác nhận', BadgeTone.success),
      2 => ('Đã khám xong', BadgeTone.info),
      _ => ('Chờ xác nhận', BadgeTone.warning),
    };
  }

  (String, BadgeTone)? get _paymentMeta {
    if (appointment.status != 2 || appointment.isCanceled) return null;
    return switch (appointment.paymentStatus) {
      'paid' => ('Đã thanh toán', BadgeTone.success),
      'pending' => ('Chờ duyệt TT', BadgeTone.warning),
      'unpaid' => ('Chưa thanh toán', BadgeTone.danger),
      _ => null,
    };
  }

  Future<void> _act(BuildContext context, String action) async {
    try {
      final service = Appointments();
      if (action == 'confirm') {
        await service.statusAction(
          'doctor/confirm-appointment',
          appointment.id,
          data: {'confirmDate': DateTime.now().toIso8601String(), 'note': ''},
        );
      } else if (action == 'complete') {
        final diseaseIds = await showCompleteAppointmentDialog(context);
        if (diseaseIds == null || diseaseIds.isEmpty) return;
        await service.statusAction(
          'doctor/complete',
          appointment.id,
          data: {'diseaseIds': diseaseIds},
        );
      } else {
        final reason = await _askReason(context);
        if (reason == null || reason.trim().isEmpty) return;
        if (doctor) {
          await service.statusAction(
            'doctor/cancel-appointment',
            appointment.id,
            data: {'reason': reason.trim()},
          );
        } else {
          await service.patientCancel(appointment.id, reason.trim());
        }
      }
      refresh();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
  }

  Future<String?> _askReason(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) => const _CancelReasonDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusTone) = _statusMeta;
    final paymentMeta = _paymentMeta;
    final canCancelOrConfirm =
        (!doctor && appointment.status < 2 ||
            doctor && appointment.status <= 1) &&
        !appointment.isCanceled;

    return Card(
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailScreen(
                appointment: appointment,
                doctor: doctor,
              ),
            ),
          );
          if (changed == true) refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    imagePath: appointment.avatar,
                    name: appointment.name,
                    radius: 21,
                    fallbackIcon: doctor
                        ? Icons.person_outline
                        : Icons.medical_services_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.name ?? 'Lịch khám #${appointment.id}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã lịch #${appointment.id}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(label: statusLabel, tone: statusTone),
                      if (paymentMeta != null) ...[
                        const SizedBox(height: 6),
                        StatusBadge(
                          label: paymentMeta.$1,
                          tone: paymentMeta.$2,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatDateTime(
                              appointment.time,
                              fallback: 'Chưa có thời gian',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (appointment.rescheduled)
                          const StatusBadge(
                            label: 'Đã đổi lịch',
                            tone: BadgeTone.neutral,
                          ),
                      ],
                    ),
                    if (appointment.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appointment.address,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (appointment.isCanceled && appointment.cancelReason != null) ...[
                const SizedBox(height: 10),
                ClinicBanner(
                  message: 'Lý do hủy: ${appointment.cancelReason!}',
                  tone: BadgeTone.danger,
                ),
              ] else if (appointment.note != null &&
                  appointment.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  appointment.note!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
              if (canCancelOrConfirm ||
                  (doctor && appointment.status == 0 && !appointment.isCanceled) ||
                  (!doctor &&
                      appointment.status == 2 &&
                      !appointment.isCanceled)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canCancelOrConfirm && doctor && appointment.status == 1)
                      FilledButton.tonalIcon(
                        onPressed: () => _act(context, 'confirm'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Xác nhận'),
                      ),
                    if (doctor &&
                        appointment.status == 0 &&
                        !appointment.isCanceled)
                      FilledButton.icon(
                        onPressed: () => _act(context, 'complete'),
                        icon: const Icon(
                          Icons.medical_services_outlined,
                          size: 18,
                        ),
                        label: const Text('Chẩn đoán và hoàn tất khám'),
                      ),
                    if (canCancelOrConfirm)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerFg,
                        ),
                        onPressed: () => _act(context, 'cancel'),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Hủy lịch'),
                      ),
                    if (!doctor &&
                        appointment.status == 2 &&
                        !appointment.isCanceled)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentScreen(appointmentId: appointment.id),
                          ),
                        ).then((_) => refresh()),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('Xem hóa đơn / thanh toán'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Lý do hủy lịch'),
    content: TextField(
      controller: _field,
      autofocus: true,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Nhập lý do hủy lịch hẹn...',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
