import 'package:flutter/material.dart';

import '../services/appointments.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

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
      _error = formatApiError(error);
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
      _error = formatApiError(error);
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
        apTime: _slot!,
        address: _address.text.trim(),
        note: _note.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = formatApiError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic>? get _selectedDoctor {
    for (final doc in _doctors) {
      if ((doc['id'] as num?)?.toInt() == _doctorId) return doc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _selectedDoctor;
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch khám')),
      body: _loading && _doctors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
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
                          const SectionHeader(
                            title: '1. Chọn bác sĩ',
                            subtitle: 'Lựa chọn bác sĩ phụ trách buổi khám',
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _doctorId,
                            decoration: const InputDecoration(
                              labelText: 'Bác sĩ',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                            items: [
                              for (final doc in _doctors)
                                DropdownMenuItem(
                                  value: (doc['id'] as num).toInt(),
                                  child: Text(
                                    '${doc['name'] ?? doc['doctorName'] ?? 'Bác sĩ'}',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              _doctorId = value;
                              _loadSlots();
                            },
                          ),
                          if (doctor != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  AppAvatar(
                                    imagePath: doctor['avatar'] as String?,
                                    name:
                                        '${doctor['name'] ?? doctor['doctorName'] ?? ''}',
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${doctor['name'] ?? doctor['doctorName'] ?? 'Bác sĩ'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if ((doctor['phone'] as String?)
                                                ?.isNotEmpty ==
                                            true)
                                          Text(
                                            'SĐT: ${doctor['phone']}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                            title: '2. Ngày & khung giờ khám',
                            subtitle: 'Các khung giờ trống theo ca trực bác sĩ',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _chooseDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text('Ngày khám: ${formatDate(_date)}'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_slots.isEmpty)
                            const ClinicBanner(
                              message: 'Ngày này chưa có khung giờ trống.',
                              tone: BadgeTone.warning,
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
                                    onSelected: (_) =>
                                        setState(() => _slot = slot),
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
                          const SectionHeader(
                            title: '3. Địa điểm & ghi chú',
                            subtitle: 'Thông tin bổ sung cho buổi khám',
                          ),
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
                              labelText: 'Ghi chú (không bắt buộc)',
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
                ],
              ),
              ),
            ),
      bottomNavigationBar: _loading && _doctors.isEmpty
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Align(
                    alignment: Alignment.center,
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _saving ? 'Đang đặt lịch…' : 'Xác nhận đặt lịch',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
