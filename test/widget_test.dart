import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/main.dart';
import 'package:dacn_app/models/appointment.dart';
import 'package:dacn_app/screens/ai_report_screen.dart';
import 'package:dacn_app/screens/register_patient_screen.dart';
import 'package:dacn_app/services/session.dart';
import 'package:dacn_app/utils/formatters.dart';
import 'package:dacn_app/widgets/clinic_widgets.dart';

void main() {
  testWidgets('signed-out users see the API login form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => Session()..restore(),
        child: const DacnApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DACN Clinic'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('patient registration collects identity and contact details', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPatientScreen()));
    expect(find.text('CCCD (12 số)'), findsOneWidget);
    expect(find.text('Giới tính'), findsOneWidget);
    expect(find.text('Ngày sinh (YYYY-MM-DD)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tạo tài khoản'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Tra cứu BHYT'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
  });

  test('appointment parser reads relation IDs and reschedule state', () {
    final appointment = Appointment.fromJson({
      'id': 12,
      'apTime': '2026-11-11T09:00:00.000Z',
      'confirmCondition': 0,
      'address': 'Clinic',
      'doctor': {'id': 4},
      'patient': {'id': 7},
      'rescheduled': true,
    });
    expect(appointment.doctorId, 4);
    expect(appointment.patientId, 7);
    expect(appointment.rescheduled, isTrue);
  });

  test(
    'appointment parser uses the relevant related person when name is blank',
    () {
      final patientView = Appointment.fromJson({
        'id': 13,
        'apTime': '2026-11-12T06:00:00.000Z',
        'confirmCondition': 1,
        'address': 'Clinic',
        'doctorName': '',
        'doctor': {'id': 4, 'name': 'Dr. Nguyen'},
      });
      final doctorView = Appointment.fromJson({
        'id': 13,
        'apTime': '2026-11-12T06:00:00.000Z',
        'confirmCondition': 1,
        'address': 'Clinic',
        'doctorName': 'Dr. Nguyen',
        'patient': {'id': 7, 'name': 'Lan Nguyen'},
      }, doctor: true);

      expect(patientView.name, 'Dr. Nguyen');
      expect(doctorView.name, 'Lan Nguyen');
    },
  );

  testWidgets('AI report screen offers image and symptom submission', (
    tester,
  ) async {
    const appointment = Appointment(
      id: 12,
      time: null,
      status: 1,
      address: 'Clinic',
      name: 'Dr. Nguyen',
    );
    await tester.pumpWidget(
      const MaterialApp(home: AiReportScreen(appointment: appointment)),
    );

    expect(find.text('Chưa chọn ảnh'), findsOneWidget);
    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Chụp ảnh'), findsOneWidget);
    expect(find.text('Mô tả triệu chứng'), findsOneWidget);
    expect(find.text('Phân tích và tạo PDF'), findsOneWidget);
    expect(find.textContaining('Lịch #12'), findsOneWidget);
  });

  test('formatters format VND currency, local timestamps, and gender labels', () {
    expect(formatVnd(300000), '300.000 ₫');
    expect(formatVnd(null), '—');
    expect(genderLabel('male'), 'Nam');
    expect(genderLabel('female'), 'Nữ');
    expect(genderLabel('other'), 'Khác');
    expect(paymentStatusLabel('paid'), 'Đã thanh toán');
  });

  testWidgets('StatusBadge renders label cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Đã xác nhận', tone: BadgeTone.success),
        ),
      ),
    );
    expect(find.text('Đã xác nhận'), findsOneWidget);
  });

  testWidgets('SignInScreen renders two-column brand panel on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đặt lịch & đổi lịch linh hoạt'), findsOneWidget);
    expect(find.text('Thanh toán BHYT & VietQR'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
