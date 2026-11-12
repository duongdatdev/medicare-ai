import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';
import 'admin_diseases_screen.dart';
import 'admin_doctor_form.dart';
import 'admin_news_screen.dart';

class AdminOverview extends StatefulWidget {
  const AdminOverview({super.key});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  late Future<_OverviewData> _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      Api.instance.list('/admin/doctor-salaries'),
      Api.instance.list('/doctor/list'),
      Api.instance.list('/doctor/shift-overview'),
    ]).then((result) => _OverviewData(result[0], result[1], result[2]));
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _data;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_OverviewData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return ErrorStateView(
          message: formatApiError(snapshot.error!),
          onRetry: () => setState(_reload),
          retryLabel: 'Không tải được dữ liệu. Thử lại',
        );
      }
      final data = snapshot.data!;
      final totalPayroll = data.salaries.fold<int>(
        0,
        (sum, row) =>
            sum + (((row as Map<String, dynamic>)['salary'] as num?)?.toInt() ?? 0),
      );

      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(
              title: 'Tổng quan phòng khám',
              subtitle: 'Theo dõi đội ngũ bác sĩ, ca trực và bảng lương',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 4 : 2;
                const spacing = 12.0;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: MetricTile(
                        label: 'Bác sĩ',
                        value: '${data.doctors.length}',
                        icon: Icons.medical_services_outlined,
                        tone: BadgeTone.primary,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: MetricTile(
                        label: 'Bảng lương',
                        value: '${data.salaries.length}',
                        icon: Icons.receipt_long_outlined,
                        tone: BadgeTone.info,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: MetricTile(
                        label: 'Phân ca',
                        value: '${data.shifts.length}',
                        icon: Icons.schedule_outlined,
                        tone: BadgeTone.warning,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: MetricTile(
                        label: 'Tổng quỹ lương',
                        value: formatVnd(totalPayroll),
                        icon: Icons.payments_outlined,
                        tone: BadgeTone.success,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Quản lý danh mục',
              subtitle: 'Bảng giá dịch vụ khám và bản tin phòng khám',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final cards = [
                  _QuickAdminTile(
                    icon: Icons.medical_information_outlined,
                    title: 'Bảng giá và dịch vụ khám',
                    subtitle: 'Cập nhật phí khám & danh mục BHYT',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDiseasesScreen(),
                      ),
                    ),
                  ),
                  _QuickAdminTile(
                    icon: Icons.newspaper_outlined,
                    title: 'Quản lý tin tức',
                    subtitle: 'Đăng bài truyền thông sức khỏe mới',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNewsScreen(),
                      ),
                    ),
                  ),
                ];
                if (!wide) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 10),
                      cards[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Đội ngũ bác sĩ',
              subtitle: '${data.doctors.length} bác sĩ đang hoạt động',
              trailing: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDoctorForm(),
                      ),
                    ).then((saved) {
                      if (saved == true && context.mounted) setState(_reload);
                    }),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Thêm bác sĩ'),
              ),
            ),
            const SizedBox(height: 10),
            if (data.doctors.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có bác sĩ nào trong danh sách.'),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.doctors.length; i++) ...[
                      if (i > 0) const Divider(),
                      _doctorTile(
                        context,
                        data.doctors[i] as Map<String, dynamic>,
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'Tổng giờ và lương',
              subtitle: 'Tính theo tổng giờ phân ca thực tế của từng bác sĩ',
            ),
            const SizedBox(height: 10),
            if (data.salaries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có dữ liệu bảng lương.'),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.salaries.length; i++) ...[
                      if (i > 0) const Divider(),
                      _salaryTile(data.salaries[i] as Map<String, dynamic>),
                    ],
                  ],
                ),
              ),
            if (data.shifts.isNotEmpty) ...[
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Phân ca đang hoạt động',
                subtitle: '${data.shifts.length} ca trực sắp tới',
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.shifts.take(8).length; i++) ...[
                      if (i > 0) const Divider(),
                      _shiftTile(data.shifts[i] as Map<String, dynamic>),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _doctorTile(BuildContext context, Map<String, dynamic> row) =>
      ListTile(
        leading: AppAvatar(
          imagePath: row['avatar'] as String?,
          name: '${row['name'] ?? 'Bác sĩ'}',
        ),
        title: Text(
          '${row['name'] ?? 'Bác sĩ'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${row['phone'] ?? ''} · ${row['email'] ?? ''}'),
        trailing: IconButton(
          tooltip: 'Sửa bác sĩ',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminDoctorForm(doctorId: (row['id'] as num).toInt()),
                ),
              ).then((saved) {
                if (saved == true && context.mounted) {
                  setState(_reload);
                }
              }),
        ),
      );

  Widget _salaryTile(Map<String, dynamic> row) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.payments_outlined,
        size: 18,
        color: AppColors.primaryDark,
      ),
    ),
    title: Text(
      '${row['name'] ?? row['doctorName'] ?? 'Bác sĩ'}',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${formatHours(row['totalHours'])} · ${formatVnd(row['hourlyRate'] ?? 300000)}/giờ',
    ),
    trailing: Text(
      formatVnd(row['salary']),
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryDark,
        fontSize: 15,
      ),
    ),
  );

  Widget _shiftTile(Map<String, dynamic> row) {
    final doctor = row['doctor'] as Map<String, dynamic>?;
    final endDt = DateTime.tryParse('${row['endTime'] ?? ''}');
    final endLabel = endDt != null ? formatTimeOnly(endDt) : '';
    return ListTile(
      leading: const Icon(Icons.schedule_outlined, color: AppColors.primary),
      title: Text(
        '${doctor?['name'] ?? 'Bác sĩ'} · ${row['type'] ?? 'Ca trực'}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatIsoDateTime(row['startTime'])}${endLabel.isNotEmpty ? ' – $endLabel' : ''}',
      ),
      trailing: const StatusBadge(label: 'Hoạt động', tone: BadgeTone.success),
    );
  }
}

class _QuickAdminTile extends StatelessWidget {
  const _QuickAdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _OverviewData {
  const _OverviewData(this.salaries, this.doctors, this.shifts);
  final List<dynamic> salaries;
  final List<dynamic> doctors;
  final List<dynamic> shifts;
}
