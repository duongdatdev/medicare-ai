import 'package:flutter/material.dart';

import '../services/api.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

class ReExaminationScreen extends StatefulWidget {
  const ReExaminationScreen({required this.patientId, super.key});
  final int patientId;

  @override
  State<ReExaminationScreen> createState() => _ReExaminationScreenState();
}

class _ReExaminationScreenState extends State<ReExaminationScreen> {
  final _address = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  List<String> _slots = [];
  String? _slot;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  Future<void> _chooseDate(int doctorId) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null) return;
    setState(() {
      _date = date;
      _loading = true;
      _slot = null;
      _error = null;
    });
    try {
      final response = await Api.instance.client.get<List<dynamic>>(
        '/doctor/availability',
        queryParameters: {
          'doctorId': doctorId,
          'date': formatDateApi(date),
        },
      );
      _slots = (response.data ?? []).cast<String>();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final doctorId = maybeSession(context, listen: false)?.doctorId;
    if (doctorId == null || _slot == null || _address.text.trim().isEmpty) {
      setState(() => _error = 'Chọn ngày, khung giờ và nhập địa chỉ khám');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Api.instance.client.post(
        '/doctor/re-examination',
        data: {
          'patientId': widget.patientId,
          'apTime': _slot!,
          'address': _address.text.trim(),
          'note': _note.text.trim(),
        },
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

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = maybeSession(context)?.doctorId;
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch tái khám')),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: '1. Ngày & giờ tái khám',
                      subtitle: 'Bệnh nhân #${widget.patientId}',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: doctorId == null
                            ? null
                            : () => _chooseDate(doctorId),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('${formatDate(_date)} · Chọn ngày'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_slots.isEmpty)
                      const ClinicBanner(
                        message:
                            'Nhấn "Chọn ngày" để tải khung giờ trống theo ca trực của bạn.',
                        tone: BadgeTone.info,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in _slots)
                            ChoiceChip(
                              label: Text(
                                formatTimeOnly(DateTime.parse(slot)),
                              ),
                              selected: _slot == slot,
                              onSelected: (_) => setState(() => _slot = slot),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: '2. Địa điểm & dặn dò'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ khám',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú cho bệnh nhân',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              ClinicBanner(message: _error!, tone: BadgeTone.danger),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.event_available_outlined),
              label: Text(_saving ? 'Đang lưu…' : 'Tạo lịch đã xác nhận'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
