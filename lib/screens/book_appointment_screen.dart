import 'package:flutter/material.dart';

import '../services/appointments.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _service = Appointments();
  final _address = TextEditingController();
  final _note = TextEditingController();
  List<Map<String, dynamic>> _doctors = [];
  List<String> _slots = [];
  int? _doctorId;
  String? _slot;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      _doctors = await _service.doctors();
      if (_doctors.isNotEmpty) {
        _doctorId = (_doctors.first['id'] as num).toInt();
        await _loadSlots();
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSlots() async {
    final id = _doctorId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _slot = null;
    });
    try {
      _slots = await _service.availability(id, _date);
      _error = null;
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date != null) {
      _date = date;
      await _loadSlots();
    }
  }

  Future<void> _submit() async {
    if (_doctorId == null || _slot == null || _address.text.trim().isEmpty) {
      setState(() => _error = 'Chọn bác sĩ, giờ khám và nhập địa chỉ');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.create(
        doctorId: _doctorId!,
        time: DateTime.parse(_slot!).toLocal(),
        address: _address.text.trim(),
        note: _note.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt lịch khám')),
    body: _loading && _doctors.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _doctorId,
                decoration: const InputDecoration(labelText: 'Bác sĩ'),
                items: [
                  for (final doctor in _doctors)
                    DropdownMenuItem(
                      value: (doctor['id'] as num).toInt(),
                      child: Text(
                        '${doctor['name'] ?? doctor['doctorName'] ?? 'Bác sĩ'}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  _doctorId = value;
                  _loadSlots();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('${_date.day}/${_date.month}/${_date.year}'),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_slots.isEmpty)
                const Text('Ngày này chưa có khung giờ trống')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              const SizedBox(height: 16),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ khám'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Đang đặt lịch…' : 'Xác nhận đặt lịch'),
              ),
            ],
          ),
  );
}
