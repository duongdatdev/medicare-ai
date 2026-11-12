import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_form_fields.dart';
import '../widgets/clinic_widgets.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  String? _gender;
  String? _email;
  String? _cccd;
  String? _avatar;
  Map<String, dynamic>? _insurance;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _birthDate.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/patient/me',
      );
      final data = response.data ?? {};
      _name.text = '${data['name'] ?? ''}';
      _gender = (data['gender'] as String?)?.trim();
      _age.text = data['age'] == null ? '' : '${data['age']}';
      _birthDate.text = '${data['birthDate'] ?? ''}';
      _phone.text = '${data['phone'] ?? ''}';
      _address.text = '${data['address'] ?? ''}';
      _email = data['email'] as String?;
      _cccd = data['cccd'] as String?;
      _avatar = data['avatar'] as String?;
      _insurance = data['insurance'] as Map<String, dynamic>?;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
      if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
      if (_age.text.trim().isNotEmpty) 'age': int.tryParse(_age.text.trim()),
      if (_birthDate.text.trim().isNotEmpty)
        'birthDate': _birthDate.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
    };
    try {
      await Api.instance.client.put('/patient/me', data: data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      }
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
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : ResponsiveCenter(
            maxWidth: 720,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  if (widget.embedded) ...[
                    const SectionHeader(
                      title: 'Hồ sơ bệnh nhân',
                      subtitle: 'Quản lý thông tin cá nhân và thẻ BHYT',
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          AppAvatar(
                            imagePath: _avatar,
                            name: _name.text,
                            radius: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name.text.trim().isEmpty
                                      ? 'Bệnh nhân'
                                      : _name.text.trim(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email ?? 'Chưa có email',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInsuranceCard(),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Thông tin cá nhân',
                            subtitle: 'Cập nhật hồ sơ liên hệ của bạn',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
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
                                  validator: (value) =>
                                      value != null &&
                                          value.isNotEmpty &&
                                          int.tryParse(value) == null
                                      ? 'Nhập tuổi hợp lệ'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DatePickerFormField(
                            controller: _birthDate,
                            labelText: 'Ngày sinh (YYYY-MM-DD)',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
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
                            title: 'Thông tin định danh',
                            subtitle: 'Được đồng bộ cố định theo tài khoản',
                          ),
                          const SizedBox(height: 8),
                          KeyValueRow(
                            icon: Icons.badge_outlined,
                            label: 'CCCD',
                            value: _cccd ?? 'Chưa có',
                          ),
                          KeyValueRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _email ?? 'Chưa có',
                          ),
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
                    label: Text(_saving ? 'Đang lưu…' : 'Lưu hồ sơ'),
                  ),
                ],
                ),
              ),
            ),
          );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ bệnh nhân')),
      body: content,
    );
  }

  Widget _buildInsuranceCard() {
    final cardNumber = _insurance?['cardNumber'] as String?;
    final rate = _insurance?['rate'] as num?;
    final status = _insurance?['status'] as String?;
    final (badgeText, badgeTone) = switch (status) {
      'valid' => ('Còn hiệu lực', BadgeTone.success),
      'expired' => ('Hết hạn', BadgeTone.danger),
      'not_yet_valid' => ('Chưa hiệu lực', BadgeTone.warning),
      _ =>
        cardNumber != null
            ? ('Đã liên kết', BadgeTone.primary)
            : ('Chưa có', BadgeTone.neutral),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bảo hiểm y tế (BHYT)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                StatusBadge(label: badgeText, tone: badgeTone),
              ],
            ),
            const SizedBox(height: 10),
            KeyValueRow(
              label: 'Mã BHYT',
              value: cardNumber ?? 'Chưa có thông tin BHYT',
            ),
            if (rate != null)
              KeyValueRow(
                label: 'Mức hưởng',
                value: '${(rate * 100).round()}%',
              ),
            if (_insurance?['validFrom'] != null &&
                _insurance?['validTo'] != null)
              KeyValueRow(
                label: 'Thời hạn',
                value:
                    '${_insurance!['validFrom']} – ${_insurance!['validTo']}',
              ),
          ],
        ),
      ),
    );
  }
}
