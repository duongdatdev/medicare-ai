// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:dacn_app/main.dart';
import 'package:dacn_app/services/session.dart';
import 'package:dacn_app/models/appointment.dart';
import 'package:dacn_app/screens/register_patient_screen.dart';
import 'package:dacn_app/screens/ai_report_screen.dart';

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
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('patient registration collects identity and contact details', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPatientScreen()));
    expect(find.text('CCCD (12 số)'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Ngày sinh (YYYY-MM-DD)'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
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
}
