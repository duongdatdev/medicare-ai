import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_form_fields.dart';
import '../widgets/clinic_widgets.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();
  final _cccd = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _gender = 'male';
  bool _obscurePassword = true;
  bool _busy = false;
  bool _lookingUp = false;
  Map<String, dynamic>? _bhytResult;
  String? _bhytError;

  @override
  void dispose() {
    _cccd.dispose();
    _name.dispose();
    _age.dispose();
    _birthDate.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final cccd = _cccd.text.trim();
    final birthDate = _birthDate.text.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(cccd) || birthDate.isEmpty) {
      setState(() {
        _bhytResult = null;
        _bhytError = 'Nhập đúng CCCD 12 số và ngày sinh trước khi tra cứu.';
      });
      return;
    }
    setState(() {
      _lookingUp = true;
      _bhytError = null;
    });
    try {
      final result = await Api.instance.client.post<Map<String, dynamic>>(
        '/auth/bhyt-lookup',
        data: {'cccd': cccd, 'birthDate': birthDate},
      );
      if (mounted) {
        setState(() {
          _bhytResult = result.data ?? {};
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _bhytResult = null;
          _bhytError = formatApiError(error);
        });
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = FormData.fromMap({
        'cccd': _cccd.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'name': _name.text.trim(),
        'gender': _gender ?? 'male',
        'age': _age.text.trim(),
        'birthDate': _birthDate.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      await Api.instance.client.post('/auth/register', data: data);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncAgeFromBirthDate(DateTime picked) {
    if (_age.text.trim().isNotEmpty) return;
    final now = DateTime.now();
    var age = now.year - picked.year;
    if (now.month < picked.month ||
        (now.month == picked.month && now.day < picked.day)) {
      age--;
    }
    if (age >= 0) _age.text = '$age';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng ký bệnh nhân')),
    body: ResponsiveCenter(
      maxWidth: 680,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const ClinicBanner(
              message:
                  'Tạo hồ sơ bệnh nhân để đặt lịch khám, tra cứu thẻ BHYT tự động và nhận hỗ trợ AI trước buổi khám.',
              tone: BadgeTone.primary,
              icon: Icons.medical_services_outlined,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Thông tin cá nhân'),
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
                    TextFormField(
                      controller: _cccd,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CCCD (12 số)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Vui lòng nhập CCCD';
                        if (!RegExp(r'^\d{12}$').hasMatch(trimmed)) {
                          return 'CCCD cần đúng 12 số';
                        }
                        return null;
                      },
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
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Chọn giới tính' : null,
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
                            validator: (value) {
                              final parsed = int.tryParse(value?.trim() ?? '');
                              if (parsed == null || parsed < 0 || parsed > 130) {
                                return 'Tuổi không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DatePickerFormField(
                      controller: _birthDate,
                      labelText: 'Ngày sinh (YYYY-MM-DD)',
                      onPicked: _syncAgeFromBirthDate,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Vui lòng nhập ngày sinh';
                        if (DateTime.tryParse(text) == null) {
                          return 'Định dạng ngày YYYY-MM-DD';
                        }
                        return null;
                      },
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
                    const SectionHeader(title: 'Liên hệ & Tài khoản'),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => _required(v, 'số điện thoại'),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty || !text.contains('@')) {
                          return 'Nhập email hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        helperText: 'Tối thiểu 8 ký tự',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 8) {
                          return 'Mật khẩu cần ít nhất 8 ký tự';
                        }
                        return null;
                      },
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
                    const SectionHeader(
                      title: 'Kiểm tra quyền lợi BHYT',
                      subtitle: 'Dựa trên CCCD và ngày sinh đã nhập',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _lookingUp ? null : _lookup,
                        icon: _lookingUp
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.health_and_safety_outlined),
                        label: const Text('Tra cứu BHYT'),
                      ),
                    ),
                    if (_bhytError != null) ...[
                      const SizedBox(height: 12),
                      ClinicBanner(
                        message: _bhytError!,
                        tone: BadgeTone.warning,
                      ),
                    ],
                    if (_bhytResult != null) ...[
                      const SizedBox(height: 12),
                      _buildBhytResult(_bhytResult!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(_busy ? 'Đang đăng ký…' : 'Tạo tài khoản'),
            ),
          ],
          ),
        ),
      ),
    ),
  );

  Widget _buildBhytResult(Map<String, dynamic> data) {
    final found = data['found'] == true;
    if (!found) {
      return const ClinicBanner(
        message: 'Không tìm thấy thẻ BHYT trong hệ thống tra cứu.',
        tone: BadgeTone.neutral,
      );
    }
    final ratePct = (((data['rate'] as num?) ?? 0) * 100).round();
    final valid = data['status'] == 'valid';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm thấy thẻ ${data['cardNumber'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              StatusBadge(
                label: valid ? 'Còn hiệu lực' : 'Hết hạn',
                tone: valid ? BadgeTone.success : BadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mức hưởng: $ratePct% · Hạn thẻ: ${data['validTo'] ?? '—'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập $label' : null;
}
