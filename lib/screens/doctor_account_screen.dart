import 'package:flutter/material.dart';

import '../services/appointments.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../widgets/clinic_widgets.dart';

/// Doctor account & workspace summary screen for the third doctor tab.
class DoctorAccountScreen extends StatefulWidget {
  const DoctorAccountScreen({super.key});

  @override
  State<DoctorAccountScreen> createState() => _DoctorAccountScreenState();
}

class _DoctorAccountScreenState extends State<DoctorAccountScreen> {
  final _appointments = Appointments();
  late Future<_DoctorSummary> _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _summary = Future.wait([
      Api.instance.list('/doctor/my-shifts'),
      _appointments.doctorList(1),
      _appointments.doctorList(0),
      _appointments.doctorList(2),
    ]).then((results) {
      final shifts = results[0];
      final activeShifts = shifts
          .where((item) => item is Map && item['status'] == 'ACTIVE')
          .length;
      return _DoctorSummary(
        activeShifts: activeShifts,
        totalShifts: shifts.length,
        pendingAppointments: results[1].length,
        confirmedAppointments: results[2].length,
        completedAppointments: results[3].length,
      );
    });
  }

  Future<void> _confirmLogout() async {
    final session = maybeSession(context, listen: false);
    if (session == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục quản lý lịch khám và ca trực.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await session.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = maybeSession(context);
    final doctorName = session?.name?.isNotEmpty == true
        ? session!.name!
        : 'Bác sĩ phòng khám';

    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AppAvatar(
                    imagePath: session?.avatarUrl,
                    name: doctorName,
                    radius: 32,
                    fallbackIcon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            const StatusBadge(
                              label: 'Bác sĩ',
                              tone: BadgeTone.primary,
                              icon: Icons.verified_user_outlined,
                            ),
                            if (session?.doctorId != null)
                              StatusBadge(
                                label: 'Mã BS #${session!.doctorId}',
                                tone: BadgeTone.neutral,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Tổng quan công việc',
            subtitle: 'Thống kê nhanh ca trực và lịch khám hiện tại',
          ),
          const SizedBox(height: 12),
          FutureBuilder<_DoctorSummary>(
            future: _summary,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return ClinicBanner(
                  message: 'Không tải được thống kê công việc.',
                  tone: BadgeTone.warning,
                  trailing: TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Thử lại'),
                  ),
                );
              }
              final data = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 4 : 2;
                  const spacing = 12.0;
                  final tileWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: MetricTile(
                          label: 'Ca đang hoạt động',
                          value: '${data.activeShifts}',
                          icon: Icons.schedule,
                          tone: BadgeTone.primary,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: MetricTile(
                          label: 'Lịch chờ xác nhận',
                          value: '${data.pendingAppointments}',
                          icon: Icons.hourglass_top_rounded,
                          tone: BadgeTone.warning,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: MetricTile(
                          label: 'Lịch đã xác nhận',
                          value: '${data.confirmedAppointments}',
                          icon: Icons.event_available_outlined,
                          tone: BadgeTone.success,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: MetricTile(
                          label: 'Đã khám xong',
                          value: '${data.completedAppointments}',
                          icon: Icons.task_alt_outlined,
                          tone: BadgeTone.info,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.medical_information_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('Quy trình khám bệnh'),
                  subtitle: Text(
                    'Xác nhận lịch hẹn, xem báo cáo AI bệnh nhân và chọn dịch vụ khi hoàn tất khám để xuất hóa đơn BHYT.',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.dangerFg,
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: AppColors.dangerFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Kết thúc phiên làm việc hiện tại'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: session == null ? null : _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorSummary {
  const _DoctorSummary({
    required this.activeShifts,
    required this.totalShifts,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
  });

  final int activeShifts;
  final int totalShifts;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
}

