import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointments.dart';

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

  @override
  void initState() {
    super.initState();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  Future<void> _reschedule(String slot) async {
    setState(() => _saving = true);
    try {
      await Appointments().reschedule(
        widget.appointment.id,
        DateTime.parse(slot).toLocal(),
        doctor: widget.doctor,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Chi tiết lịch #${widget.appointment.id}')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Không tải được chi tiết: ${snapshot.error}'),
          );
        }
        final detail = snapshot.data!;
        final mayReschedule =
            widget.appointment.status == 0 &&
            !widget.appointment.rescheduled &&
            widget.appointment.cancelReason == null;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              'Bệnh nhân / bác sĩ',
              '${detail['patientName'] ?? detail['doctorName'] ?? widget.appointment.name ?? '—'}',
            ),
            _field(
              'Thời gian',
              '${detail['apTime'] ?? widget.appointment.time ?? '—'}',
            ),
            _field(
              'Địa chỉ',
              '${detail['address'] ?? widget.appointment.address}',
            ),
            _field(
              'Ghi chú',
              '${detail['doctorNote'] ?? detail['note'] ?? '—'}',
            ),
            if (detail['cancelReason'] != null)
              _field('Lý do hủy', '${detail['cancelReason']}'),
            if (mayReschedule) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.event_repeat),
                label: const Text('Chọn ngày đổi lịch'),
              ),
              if (_loadingSlots)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  children: [
                    for (final slot in _slots)
                      ActionChip(
                        label: Text(
                          DateTime.parse(slot)
                              .toLocal()
                              .toString()
                              .substring(0, 16),
                        ),
                        onPressed: _saving ? null : () => _reschedule(slot),
                      ),
                  ],
                ),
              if (widget.appointment.doctorId == null)
                const Text(
                  'Lịch này chưa có mã bác sĩ để tra khung giờ trống.',
                ),
            ],
          ],
        );
      },
    ),
  );

  Widget _field(String label, String value) => Card(
    child: ListTile(title: Text(label), subtitle: Text(value)),
  );
}
