import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_form_fields.dart';
import '../widgets/clinic_widgets.dart';

class AdminDoctorForm extends StatefulWidget {
  const AdminDoctorForm({this.doctorId, super.key});
  final int? doctorId;

  @override
  State<AdminDoctorForm> createState() => _AdminDoctorFormState();
}

class _AdminDoctorFormState extends State<AdminDoctorForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _gender = 'male';
  XFile? _avatar;
  Uint8List? _avatarBytes;
  String? _existingAvatar;
  bool _obscurePassword = true;
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
    _name.dispose();
    _age.dispose();
    _dateOfBirth.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/doctor/detail/${widget.doctorId}',
      );
      final data = response.data ?? {};
      _name.text = '${data['name'] ?? ''}';
      _age.text = data['age'] == null ? '' : '${data['age']}';
      final rawDob = '${data['dateOfBirth'] ?? ''}';
      _dateOfBirth.text = rawDob.length >= 10 ? rawDob.substring(0, 10) : rawDob;
      _gender = (data['gender'] as String?)?.trim();
      _phone.text = '${data['phone'] ?? ''}';
      _address.text = '${data['address'] ?? ''}';
      _email.text = '${data['email'] ?? ''}';
      _existingAvatar = data['avatar'] as String?;
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

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _avatar = file;
        _avatarBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_editing && _avatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh đại diện bác sĩ')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'age': int.parse(_age.text.trim()),
        'dateOfBirth': _dateOfBirth.text.trim(),
        'gender': _gender ?? 'male',
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'email': _email.text.trim(),
      };
      if (_editing) {
        await Api.instance.client.put(
          '/doctor/update/${widget.doctorId}',
          data: body,
        );
      } else {
        body['password'] = _password.text;
        final bytes = _avatarBytes ?? await _avatar!.readAsBytes();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
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
        : ResponsiveCenter(
            maxWidth: 680,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  if (!_editing) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Ảnh đại diện bác sĩ',
                              subtitle: 'Bắt buộc khi tạo tài khoản bác sĩ mới',
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (_avatarBytes != null)
                                  ClipOval(
                                    child: Image.memory(
                                      _avatarBytes!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  const AppAvatar(radius: 32),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.image_outlined),
                                    label: Text(
                                      _avatar?.name ??
                                          'Chọn ảnh đại diện (bắt buộc)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (_existingAvatar != null &&
                      _existingAvatar!.isNotEmpty) ...[
                    Card(
                      child: ListTile(
                        leading: AppAvatar(
                          imagePath: _existingAvatar,
                          name: _name.text,
                          radius: 26,
                        ),
                        title: Text(
                          _name.text.trim().isEmpty
                              ? 'Bác sĩ'
                              : _name.text.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_email.text),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Thông tin bác sĩ'),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Họ tên',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => _required(v, 'họ tên'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: GenderDropdownField(
                                  value: _gender,
                                  onChanged: (value) =>
                                      setState(() => _gender = value),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Chọn giới tính'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _age,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tuổi',
                                    prefixIcon: Icon(Icons.numbers_outlined),
                                  ),
                                  validator: (v) =>
                                      int.tryParse(v?.trim() ?? '') == null
                                      ? 'Nhập tuổi hợp lệ'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DatePickerFormField(
                            controller: _dateOfBirth,
                            labelText: 'Ngày sinh (YYYY-MM-DD)',
                            validator: (v) =>
                                DateTime.tryParse(v?.trim() ?? '') == null
                                ? 'Nhập đúng YYYY-MM-DD'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Điện thoại',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => _required(v, 'điện thoại'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                            validator: (v) => _required(v, 'địa chỉ'),
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
                          const SectionHeader(title: 'Tài khoản đăng nhập'),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Nhập email hợp lệ'
                                : null,
                          ),
                          if (!_editing) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                helperText: 'Tối thiểu 8 ký tự',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => value == null ||
                                      value.length < 8
                                  ? 'Mật khẩu cần ít nhất 8 ký tự'
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Đang lưu…' : 'Lưu'),
                  ),
                ],
                ),
              ),
            ),
          ),
  );

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập $label' : null;
}
