import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointments.dart';
import 'appointment_detail_screen.dart';
import 'complete_appointment_dialog.dart';
import 'payment_screen.dart';

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

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.doctor)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
        ),
      Expanded(
        child: FutureBuilder<List<Appointment>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không tải được danh sách lịch hẹn'),
                    TextButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('Chưa có lịch hẹn'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_reload),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
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

  String get _status => switch (appointment.status) {
    0 => 'Đã xác nhận',
    2 => 'Đã khám xong',
    _ => 'Chờ xác nhận',
  };

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<String?> _askReason(BuildContext context) async {
    final field = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lý do hủy lịch'),
        content: TextField(controller: field, autofocus: true, maxLines: 2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
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
              children: [
                const Icon(Icons.event_available_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.name ?? 'Lịch khám #${appointment.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appointment.time?.toLocal().toString().substring(0, 16) ??
                  'Chưa có thời gian',
            ),
            if (appointment.address.isNotEmpty) Text(appointment.address),
            if (appointment.note != null) Text(appointment.note!),
            if ((!doctor && appointment.status < 2 ||
                    doctor && appointment.status <= 1) &&
                appointment.cancelReason == null)
              Wrap(
                spacing: 8,
                children: [
                  if (doctor)
                    TextButton.icon(
                      onPressed: () => _act(context, 'confirm'),
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                    ),
                  TextButton.icon(
                    onPressed: () => _act(context, 'cancel'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Hủy lịch'),
                  ),
                ],
              ),
            if (doctor && appointment.status == 0)
              FilledButton.tonalIcon(
                onPressed: () => _act(context, 'complete'),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Chẩn đoán và hoàn tất khám'),
              ),
            if (!doctor && appointment.status == 2)
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PaymentScreen(appointmentId: appointment.id),
                  ),
                ).then((_) => refresh()),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Xem hóa đơn / thanh toán'),
              ),
          ],
        ),
      ),
    ),
  );
}
