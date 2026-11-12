import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/admin_notifications_screen.dart';
import 'screens/admin_overview.dart';
import 'screens/admin_payments_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/book_appointment_screen.dart';
import 'screens/doctor_account_screen.dart';
import 'screens/doctor_shifts_screen.dart';
import 'screens/news_feed_screen.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/register_patient_screen.dart';
import 'services/api.dart';
import 'services/session.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'widgets/clinic_widgets.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Session()..restore(),
      child: const DacnApp(),
    ),
  );
}

class DacnApp extends StatelessWidget {
  const DacnApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DACN Clinic - Đặt lịch khám',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (session.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.signedIn) return const SignInScreen();
    return RoleHome(role: session.role ?? 'patient');
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _working = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await context.read<Session>().login(_email.text.trim(), _password.text);
    } catch (error) {
      if (mounted) setState(() => _error = formatApiError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 940 : 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _brandPanel(context)),
                            const SizedBox(width: 28),
                            SizedBox(width: 420, child: _loginCard(context)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _mobileHero(context),
                            const SizedBox(height: 20),
                            _loginCard(context),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _mobileHero(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DACN Clinic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Đặt lịch khám · BHYT · Hỗ trợ AI',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _brandPanel(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'DACN Clinic',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nền tảng quản lý khám chữa bệnh toàn diện dành cho bệnh nhân, bác sĩ và quản trị phòng khám.',
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const _BrandFeature(
          icon: Icons.event_available_outlined,
          title: 'Đặt lịch & đổi lịch linh hoạt',
          subtitle: 'Tra cứu khung giờ trống theo ca trực bác sĩ.',
        ),
        const SizedBox(height: 12),
        const _BrandFeature(
          icon: Icons.smart_toy_outlined,
          title: 'Báo cáo AI tiền chẩn đoán',
          subtitle: 'Phân tích hình ảnh, triệu chứng và xuất báo cáo PDF.',
        ),
        const SizedBox(height: 12),
        const _BrandFeature(
          icon: Icons.qr_code_2_outlined,
          title: 'Thanh toán BHYT & VietQR',
          subtitle: 'Tự động tính mức hưởng BHYT và xác nhận chuyển khoản.',
        ),
      ],
    ),
  );

  Widget _loginCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đặt lịch khám',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Đăng nhập bằng tài khoản của bạn để tiếp tục',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Nhập email hợp lệ'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Nhập mật khẩu' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              ClinicBanner(message: _error!, tone: BadgeTone.danger),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working ? null : _login,
                child: _working
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Đăng nhập'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPatientScreen(),
                    ),
                  );
                  if (created == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đăng ký thành công! Vui lòng đăng nhập.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Tạo tài khoản bệnh nhân'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}

class RoleHome extends StatefulWidget {
  const RoleHome({required this.role, super.key});
  final String role;

  @override
  State<RoleHome> createState() => _RoleHomeState();
}

class _RoleHomeState extends State<RoleHome> {
  int _tab = 0;
  int _patientAppointmentRevision = 0;
  int _adminUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'admin') {
      _refreshAdminUnread();
    }
  }

  Future<void> _refreshAdminUnread() async {
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/admin/notifications/unread-count',
      );
      if (mounted) {
        setState(() {
          _adminUnreadCount = (response.data?['count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {
      // AdminNotificationsScreen handles surfacing unread-count errors directly.
    }
  }

  List<String> get _tabs => switch (widget.role) {
    'doctor' => const ['Lịch khám', 'Ca trực', 'Tài khoản'],
    'admin' => const ['Quản trị', 'Thanh toán', 'Thông báo'],
    _ => const ['Tin tức', 'Lịch hẹn', 'Hồ sơ'],
  };

  String get _roleName => switch (widget.role) {
    'doctor' => 'Bác sĩ',
    'admin' => 'Quản trị',
    _ => 'Bệnh nhân',
  };

  Future<void> _openBookAppointment() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _patientAppointmentRevision++;
        _tab = 1;
      });
    }
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
    if (widget.role == 'admin') {
      _refreshAdminUnread();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = maybeSession(context);
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final extendedRail = MediaQuery.sizeOf(context).width >= 1120;
    final maxWidth = widget.role == 'admin' ? 1040.0 : 820.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (!isWide) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(_tabs[_tab], overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: StatusBadge(label: _roleName, tone: BadgeTone.primary),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: session == null ? null : () => session.logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) ...[
            NavigationRail(
              selectedIndex: _tab,
              extended: extendedRail,
              onDestinationSelected: _selectTab,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: extendedRail
                    ? SizedBox(
                        width: 216,
                        child: Row(
                          children: [
                            AppAvatar(
                              imagePath: session?.avatarUrl,
                              name: session?.name ?? _roleName,
                              radius: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session?.name?.isNotEmpty == true
                                        ? session!.name!
                                        : 'DACN Clinic',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _roleName,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : AppAvatar(
                        imagePath: session?.avatarUrl,
                        name: session?.name ?? _roleName,
                        radius: 18,
                      ),
              ),
              destinations: [
                for (final (index, label) in _tabs.indexed)
                  NavigationRailDestination(
                    icon: _tabIcon(index, selected: false),
                    selectedIcon: _tabIcon(index, selected: true),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: ResponsiveCenter(
              maxWidth: maxWidth,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: _selectTab,
                destinations: [
                  for (final (index, label) in _tabs.indexed)
                    NavigationDestination(
                      icon: _tabIcon(index, selected: false),
                      selectedIcon: _tabIcon(index, selected: true),
                      label: label,
                    ),
                ],
              ),
            ),
      floatingActionButton: widget.role == 'patient' && _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _openBookAppointment,
              icon: const Icon(Icons.add),
              label: const Text('Đặt lịch'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (widget.role == 'patient') {
      return switch (_tab) {
        0 => NewsFeedScreen(
          onBookAppointment: _openBookAppointment,
          onOpenAppointments: () => _selectTab(1),
          onOpenProfile: () => _selectTab(2),
        ),
        1 => AppointmentsScreen(
          key: ValueKey(_patientAppointmentRevision),
          doctor: false,
        ),
        _ => const PatientProfileScreen(embedded: true),
      };
    }
    if (widget.role == 'doctor') {
      return switch (_tab) {
        0 => const AppointmentsScreen(doctor: true),
        1 => const DoctorShiftsScreen(),
        _ => const DoctorAccountScreen(),
      };
    }
    return switch (_tab) {
      0 => const AdminOverview(),
      1 => const AdminPaymentsScreen(),
      _ => AdminNotificationsScreen(
        onUnreadChanged: (count) {
          if (mounted && _adminUnreadCount != count) {
            setState(() => _adminUnreadCount = count);
          }
        },
      ),
    };
  }

  Widget _tabIcon(int index, {required bool selected}) {
    final iconData = switch (widget.role) {
      'doctor' => switch (index) {
        0 => selected ? Icons.event_note : Icons.event_note_outlined,
        1 => selected ? Icons.schedule : Icons.schedule_outlined,
        _ => selected ? Icons.person : Icons.person_outline,
      },
      'admin' => switch (index) {
        0 => selected ? Icons.dashboard : Icons.dashboard_outlined,
        1 => selected ? Icons.payments : Icons.payments_outlined,
        _ => selected ? Icons.notifications : Icons.notifications_outlined,
      },
      _ => switch (index) {
        0 => selected ? Icons.newspaper : Icons.newspaper_outlined,
        1 => selected ? Icons.calendar_month : Icons.calendar_month_outlined,
        _ => selected ? Icons.person : Icons.person_outline,
      },
    };

    final icon = Icon(iconData);
    if (widget.role == 'admin' && index == 2 && _adminUnreadCount > 0) {
      return Badge.count(count: _adminUnreadCount, child: icon);
    }
    return icon;
  }
}
