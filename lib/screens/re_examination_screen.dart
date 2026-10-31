import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/session.dart';

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
    });
    try {
      final response = await Api.instance.client.get<List<dynamic>>(
        '/doctor/availability',
        queryParameters: {
          'doctorId': doctorId,
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
      _slots = (response.data ?? []).cast<String>();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final doctorId = context.read<Session>().doctorId;
    if (doctorId == null || _slot == null || _address.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.instance.client.post(
        '/doctor/re-examination',
        data: {
          'patientId': widget.patientId,
          'apTime': DateTime.parse(_slot!).toLocal().toIso8601String(),
          'address': _address.text.trim(),
          'note': _note.text.trim(),
        },
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
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = context.watch<Session>().doctorId;
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch tái khám')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton.icon(
            onPressed: doctorId == null ? null : () => _chooseDate(doctorId),
            icon: const Icon(Icons.calendar_month),
            label: Text(
              '${_date.day}/${_date.month}/${_date.year} · Chọn ngày',
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              children: [
                for (final slot in _slots)
                  ChoiceChip(
                    label: Text(
                      DateTime.parse(slot)
                          .toLocal()
                          .toString()
                          .substring(11, 16),
                    ),
                    selected: _slot == slot,
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
              ],
            ),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Địa chỉ khám'),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Ghi chú cho bệnh nhân',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu…' : 'Tạo lịch đã xác nhận'),
          ),
        ],
      ),
    );
  }
}
