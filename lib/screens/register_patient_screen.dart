import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});
  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'cccd',
      'email',
      'password',
      'name',
      'gender',
      'age',
      'birthDate',
      'phone',
      'address',
    ])
      key: TextEditingController(),
  };
  bool _busy = false;
  String? _bhyt;
  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _lookup() async {
    try {
      final result = await Api.instance.client.post<Map<String, dynamic>>(
        '/auth/bhyt-lookup',
        data: {
          'cccd': _fields['cccd']!.text.trim(),
          'birthDate': _fields['birthDate']!.text.trim(),
        },
      );
      final data = result.data ?? {};
      setState(
        () => _bhyt = data['found'] == true
            ? 'Tìm thấy thẻ ${data['cardNumber']} · mức hưởng ${(data['rate'] as num? ?? 0) * 100}%'
            : 'Không tìm thấy thẻ BHYT',
      );
    } catch (error) {
      setState(() => _bhyt = '$error');
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = FormData.fromMap({
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      });
      await Api.instance.client.post('/auth/register', data: data);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký bệnh nhân')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final entry in _fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: entry.value,
                obscureText: entry.key == 'password',
                keyboardType:
                    {
                      'age': TextInputType.number,
                      'phone': TextInputType.phone,
                      'cccd': TextInputType.number,
                    }.containsKey(entry.key)
                    ? {
                        'age': TextInputType.number,
                        'phone': TextInputType.phone,
                        'cccd': TextInputType.number,
                      }[entry.key]
                    : TextInputType.text,
                decoration: InputDecoration(labelText: _label(entry.key)),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập ${_label(entry.key).toLowerCase()}'
                    : entry.key == 'cccd' &&
                          !RegExp(r'^\d{12}$').hasMatch(value.trim())
                    ? 'CCCD cần đúng 12 số'
                    : entry.key == 'password' && value.length < 6
                    ? 'Mật khẩu cần ít nhất 6 ký tự'
                    : null,
              ),
            ),
          OutlinedButton.icon(
            onPressed: _lookup,
            icon: const Icon(Icons.health_and_safety),
            label: const Text('Tra cứu BHYT'),
          ),
          if (_bhyt != null) Text(_bhyt!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Đang đăng ký…' : 'Tạo tài khoản'),
          ),
        ],
      ),
    ),
  );
  String _label(String key) => switch (key) {
    'cccd' => 'CCCD (12 số)',
    'email' => 'Email',
    'password' => 'Mật khẩu',
    'name' => 'Họ tên',
    'gender' => 'Giới tính',
    'age' => 'Tuổi',
    'birthDate' => 'Ngày sinh (YYYY-MM-DD)',
    'phone' => 'Số điện thoại',
    _ => 'Địa chỉ',
  };
}
