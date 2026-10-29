import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api.dart';

class AdminDoctorForm extends StatefulWidget {
  const AdminDoctorForm({this.doctorId, super.key});
  final int? doctorId;
  @override
  State<AdminDoctorForm> createState() => _AdminDoctorFormState();
}

class _AdminDoctorFormState extends State<AdminDoctorForm> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'name',
      'age',
      'dateOfBirth',
      'gender',
      'phone',
      'address',
      'email',
      'password',
    ])
      key: TextEditingController(),
  };
  XFile? _avatar;
  bool _loading = false;
  bool _saving = false;
  bool get _editing => widget.doctorId != null;
  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/doctor/detail/${widget.doctorId}',
      );
      final data = response.data ?? {};
      for (final key in _fields.keys) {
        if (key != 'password') _fields[key]!.text = '${data[key] ?? ''}';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    _avatar = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || (!_editing && _avatar == null)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        for (final entry in _fields.entries)
          if (entry.key != 'password' && entry.value.text.trim().isNotEmpty)
            entry.key: entry.key == 'age'
                ? int.parse(entry.value.text)
                : entry.value.text.trim(),
      };
      if (_editing) {
        await Api.instance.client.put(
          '/doctor/update/${widget.doctorId}',
          data: body,
        );
      } else {
        body['password'] = _fields['password']!.text;
        final bytes = await _avatar!.readAsBytes();
        body['avatar'] = MultipartFile.fromBytes(
          bytes,
          filename: _avatar!.name,
        );
        await Api.instance.client.post(
          '/auth/register-doctor',
          data: FormData.fromMap(body),
        );
      }
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
    appBar: AppBar(
      title: Text(_editing ? 'Sửa thông tin bác sĩ' : 'Thêm bác sĩ'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final entry in _fields.entries)
                  if (_editing ? entry.key != 'password' : true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: entry.value,
                        obscureText: entry.key == 'password',
                        keyboardType: entry.key == 'age'
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: _label(entry.key),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập ${_label(entry.key).toLowerCase()}'
                            : entry.key == 'password' && value.length < 6
                            ? 'Mật khẩu cần ít nhất 6 ký tự'
                            : null,
                      ),
                    ),
                if (!_editing)
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _avatar?.name ?? 'Chọn ảnh đại diện (bắt buộc)',
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
                ),
              ],
            ),
          ),
  );
  String _label(String key) => switch (key) {
    'name' => 'Họ tên',
    'age' => 'Tuổi',
    'dateOfBirth' => 'Ngày sinh (YYYY-MM-DD)',
    'gender' => 'Giới tính',
    'phone' => 'Điện thoại',
    'address' => 'Địa chỉ',
    'email' => 'Email',
    _ => 'Mật khẩu',
  };
}
