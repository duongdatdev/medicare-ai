import 'package:flutter/material.dart';

import '../services/api.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'name',
      'gender',
      'age',
      'birthDate',
      'email',
      'phone',
      'address',
    ])
      key: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  String? _cccd;
  String? _insurance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/patient/me',
      );
      final data = response.data ?? {};
      for (final entry in _fields.entries) {
        entry.value.text = '${data[entry.key] ?? ''}';
      }
      _cccd = data['cccd'] as String?;
      final insurance = data['insurance'] as Map<String, dynamic>?;
      _insurance = insurance == null
          ? null
          : insurance['cardNumber'] as String?;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{};
    for (final entry in _fields.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        data[entry.key] = entry.key == 'age'
            ? int.tryParse(entry.value.text)
            : entry.value.text.trim();
      }
    }
    try {
      await Api.instance.client.put('/patient/me', data: data);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      }
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
    appBar: AppBar(title: const Text('Hồ sơ bệnh nhân')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final entry in _fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: entry.value,
                      keyboardType: entry.key == 'age'
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: _label(entry.key)),
                      validator: (value) =>
                          entry.key == 'age' &&
                              value != null &&
                              value.isNotEmpty &&
                              int.tryParse(value) == null
                          ? 'Nhập tuổi hợp lệ'
                          : null,
                    ),
                  ),
                ListTile(
                  title: const Text('CCCD'),
                  subtitle: Text(_cccd ?? 'Chưa có'),
                ),
                ListTile(
                  title: const Text('Mã BHYT'),
                  subtitle: Text(_insurance ?? 'Chưa có thông tin BHYT'),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu…' : 'Lưu hồ sơ'),
                ),
              ],
            ),
          ),
  );

  String _label(String key) => switch (key) {
    'name' => 'Họ và tên',
    'gender' => 'Giới tính',
    'age' => 'Tuổi',
    'birthDate' => 'Ngày sinh (YYYY-MM-DD)',
    'email' => 'Email',
    'phone' => 'Số điện thoại',
    _ => 'Địa chỉ',
  };
}
