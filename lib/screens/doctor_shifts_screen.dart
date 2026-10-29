import 'package:flutter/material.dart';

import '../services/api.dart';

class DoctorShiftsScreen extends StatefulWidget {
  const DoctorShiftsScreen({super.key});
  @override
  State<DoctorShiftsScreen> createState() => _DoctorShiftsScreenState();
}

class _DoctorShiftsScreenState extends State<DoctorShiftsScreen> {
  late Future<List<dynamic>> _shifts;
  List<dynamic> _templates = [];
  int? _selectedTemplateId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _shifts = Api.instance.list('/doctor/my-shifts');
    Api.instance.list('/doctor/shift-templates').then((value) {
      if (mounted) setState(() => _templates = value);
    });
  }

  Future<void> _register() async {
    final shiftId = _selectedTemplateId;
    if (shiftId == null) return;
    try {
      await Api.instance.client.post(
        '/doctor/register-shift',
        data: {
          'shiftId': shiftId,
          'date':
              '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        },
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _cancel(int id) async {
    try {
      await Api.instance.client.post('/doctor/cancel-assignment/$id');
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedTemplateId,
              decoration: const InputDecoration(labelText: 'Loại ca'),
              items: [
                for (final template in _templates)
                  DropdownMenuItem<int>(
                    value: (template['id'] as num).toInt(),
                    child: Text(
                      '${template['type']} · ${template['startTime']}–${template['endTime']}',
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedTemplateId = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedTemplateId == null ? null : _register,
                  child: const Text('Đăng ký ca'),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<dynamic>>(
          future: _shifts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Tải lại ca trực'),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('Chưa đăng ký ca trực'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_reload),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(
                          '${item['type'] ?? 'Ca trực'} · ${item['status'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${item['startTime'] ?? ''} – ${item['endTime'] ?? ''}',
                        ),
                        trailing: item['status'] == 'ACTIVE'
                            ? IconButton(
                                icon: const Icon(Icons.event_busy),
                                onPressed: () =>
                                    _cancel((item['id'] as num).toInt()),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
