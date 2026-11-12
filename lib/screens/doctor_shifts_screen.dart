import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

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
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _shifts = Api.instance.list('/doctor/my-shifts');
    Api.instance.list('/doctor/shift-templates').then((value) {
      if (mounted) setState(() => _templates = value);
    }).catchError((_) {});
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _shifts;
  }

  Future<void> _register() async {
    final shiftId = _selectedTemplateId;
    if (shiftId == null) return;
    setState(() => _registering = true);
    try {
      await Api.instance.client.post(
        '/doctor/register-shift',
        data: {'shiftId': shiftId, 'date': formatDateApi(_date)},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã đăng ký ca trực')));
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _registering = false);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy ca trực')));
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Đăng ký ca trực mới',
                  subtitle: 'Chọn mẫu ca và ngày làm việc trong tương lai',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Loại ca',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  items: [
                    for (final template in _templates)
                      DropdownMenuItem<int>(
                        value: (template['id'] as num).toInt(),
                        child: Text(
                          '${template['type']} · ${template['startTime']}–${template['endTime']}',
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedTemplateId = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chooseDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(formatDate(_date)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _selectedTemplateId == null || _registering
                          ? null
                          : _register,
                      child: const Text('Đăng ký ca'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              return ErrorStateView(
                message: formatApiError(snapshot.error!),
                onRetry: () => setState(_reload),
                retryLabel: 'Tải lại ca trực',
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const EmptyStateView(
                icon: Icons.event_busy_outlined,
                title: 'Chưa đăng ký ca trực',
                subtitle: 'Chọn loại ca và ngày phía trên để bắt đầu đăng ký.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index] as Map<String, dynamic>;
                  final active = item['status'] == 'ACTIVE';
                  final start = formatIsoDateTime(
                    item['startTime'],
                    fallback: '—',
                  );
                  final endDt = DateTime.tryParse('${item['endTime'] ?? ''}');
                  final endStr = endDt != null
                      ? formatTimeOnly(endDt)
                      : '${item['endTime'] ?? ''}';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primarySoft
                                  : AppColors.neutralBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.schedule_outlined,
                              color: active
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['type'] ?? 'Ca trực'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(
                                      label: active ? 'Hoạt động' : 'Đã hủy',
                                      tone: active
                                          ? BadgeTone.success
                                          : BadgeTone.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$start – $endStr',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (!active && item['duration'] != null)
                                  Text(
                                    'Thời lượng ghi nhận: ${formatHours(item['duration'])}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Hủy ca trực',
                              color: AppColors.dangerFg,
                              icon: const Icon(Icons.event_busy_outlined),
                              onPressed: () =>
                                  _cancel((item['id'] as num).toInt()),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ],
  );
}
