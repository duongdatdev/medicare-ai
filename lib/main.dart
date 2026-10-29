import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/session.dart';
import 'screens/appointments_screen.dart';
import 'screens/book_appointment_screen.dart';
import 'screens/admin_overview.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/doctor_shifts_screen.dart';
import 'screens/admin_payments_screen.dart';
import 'screens/admin_notifications_screen.dart';
import 'screens/news_feed_screen.dart';
import 'screens/register_patient_screen.dart';

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
    title: 'DACN - Đặt lịch khám',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0e7c86)),
      scaffoldBackgroundColor: const Color(0xfff4f7f9),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueGrey.shade50),
        ),
      ),
    ),
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
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đặt lịch khám',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Nhập email hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nhập mật khẩu'
                          : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
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
                                ),
                              )
                            : const Text('Đăng nhập'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPatientScreen(),
                        ),
                      ),
                      child: const Text('Tạo tài khoản bệnh nhân'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
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

  List<String> get _tabs => switch (widget.role) {
    'doctor' => ['Lịch khám', 'Ca trực', 'Tài khoản'],
    'admin' => ['Quản trị', 'Thanh toán', 'Thông báo'],
    _ => ['Tin tức', 'Lịch hẹn', 'Hồ sơ'],
  };

  String get _roleName => switch (widget.role) {
    'doctor' => 'Bác sĩ',
    'admin' => 'Quản trị viên',
    _ => 'Bệnh nhân',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_tabs[_tab]),
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: () => context.read<Session>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: widget.role == 'patient' && _tab == 0
            ? const NewsFeedScreen()
            : widget.role == 'patient' && _tab == 1
            ? const AppointmentsScreen(doctor: false)
            : _tab == 0
            ? widget.role == 'admin'
                  ? const AdminOverview()
                  : AppointmentsScreen(doctor: widget.role == 'doctor')
            : widget.role == 'patient' && _tab == 2
            ? const PatientProfileScreen()
            : widget.role == 'doctor' && _tab == 1
            ? const DoctorShiftsScreen()
            : widget.role == 'admin' && _tab == 1
            ? const AdminPaymentsScreen()
            : widget.role == 'admin' && _tab == 2
            ? const AdminNotificationsScreen()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Xin chào, $_roleName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(_tabs[_tab])),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: [
        for (final (index, label) in _tabs.indexed)
          NavigationDestination(icon: Icon(_iconFor(index)), label: label),
      ],
    ),
    floatingActionButton: widget.role == 'patient' && _tab == 1
        ? FloatingActionButton.extended(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookAppointmentScreen(),
                ),
              );
              if (created == true && mounted) setState(() {});
            },
            icon: const Icon(Icons.add),
            label: const Text('Đặt lịch'),
          )
        : null,
  );

  IconData _iconFor(int index) => switch (index) {
    1 => widget.role == 'doctor' ? Icons.schedule : Icons.receipt_long,
    2 => Icons.person_outline,
    _ => Icons.home_outlined,
  };
}
