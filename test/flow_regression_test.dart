import 'dart:convert';
import 'dart:typed_data';

import 'package:dacn_app/screens/doctor_shifts_screen.dart';
import 'package:dacn_app/screens/admin_notifications_screen.dart';
import 'package:dacn_app/screens/complete_appointment_dialog.dart';
import 'package:dacn_app/screens/appointments_screen.dart';
import 'package:dacn_app/screens/appointment_detail_screen.dart';
import 'package:dacn_app/screens/news_feed_screen.dart';
import 'package:dacn_app/screens/patient_profile_screen.dart';
import 'package:dacn_app/screens/payment_screen.dart';
import 'package:dacn_app/models/appointment.dart';
import 'package:dacn_app/main.dart';
import 'package:dacn_app/services/api.dart';
import 'package:dacn_app/services/appointments.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef StubResponse = ResponseBody Function(RequestOptions request);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.respond);

  final StubResponse respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void _useAdapter(_StubAdapter adapter) {
  Api.instance.client.httpClientAdapter = adapter;
  SharedPreferences.setMockInitialValues({});
}

void main() {
  testWidgets('profile loads BHYT and saves validated editable fields', (
    tester,
  ) async {
    late _StubAdapter adapter;
    adapter = _StubAdapter((request) {
      if (request.method == 'GET') {
        return _json({
          'name': 'Lan Nguyen',
          'age': 35,
          'email': 'lan@example.com',
          'cccd': '012345678901',
          'insurance': {'cardNumber': 'DN4012345678901'},
        });
      }
      return _json({'name': 'Lan Nguyen'});
    });
    _useAdapter(adapter);

    await tester.pumpWidget(const MaterialApp(home: PatientProfileScreen()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('DN4012345678901'), findsOneWidget);
    expect(find.text('012345678901'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tuổi hợp lệ'), findsOneWidget);
    expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);

    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '36');
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    final update = adapter.requests.singleWhere((r) => r.method == 'PUT');
    expect(update.path, '/patient/me');
    expect((update.data as Map<String, dynamic>)['age'], 36);
    expect((update.data as Map<String, dynamic>).containsKey('cccd'), isFalse);
  });

  testWidgets('payment shows bill and QR using returned VietQR payload', (
    tester,
  ) async {
    late _StubAdapter adapter;
    var gets = 0;
    adapter = _StubAdapter((request) {
      if (request.method == 'POST') {
        return _json({
          'paymentStatus': 'pending',
          'method': 'qr',
          'payable': 240000,
          'qr': {'payload': 'vietqr-payload', 'content': 'DACN21'},
        });
      }
      gets++;
      return _json({
        'total': 300000,
        'insuranceCovered': 60000,
        'payable': 240000,
        'paymentStatus': gets == 1 ? 'unpaid' : 'pending',
      });
    });
    _useAdapter(adapter);

    await tester.pumpWidget(
      const MaterialApp(home: PaymentScreen(appointmentId: 21)),
    );
    await tester.pumpAndSettle();
    expect(find.text('300000'), findsOneWidget);
    await tester.tap(find.text('Chuyển khoản VietQR'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung chuyển khoản: DACN21'), findsOneWidget);
    expect(
      adapter.requests.any(
        (r) =>
            r.method == 'POST' &&
            r.path == '/patient/appointment/21/pay' &&
            (r.data as Map<String, dynamic>)['method'] == 'qr',
      ),
      isTrue,
    );
  });

  testWidgets('doctor shift form requires choosing a template', (tester) async {
    final adapter = _StubAdapter(
      (request) => _json(
        request.path.endsWith('shift-templates')
            ? [
                {
                  'id': 4,
                  'type': 'Sáng',
                  'startTime': '08:00',
                  'endTime': '12:00',
                },
              ]
            : [],
      ),
    );
    _useAdapter(adapter);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DoctorShiftsScreen())),
    );
    await tester.pumpAndSettle();

    final register = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Đăng ký ca'),
    );
    expect(register.onPressed, isNull);
    expect(find.text('Sáng · 08:00–12:00'), findsNothing);
    expect(find.text('Loại ca'), findsOneWidget);
  });

  test('cancel and reschedule use patient API paths and verbs', () async {
    final adapter = _StubAdapter((_) => _json({'ok': true}));
    _useAdapter(adapter);

    await Appointments().patientCancel(21, 'Bận đột xuất');
    await Appointments().reschedule(
      21,
      DateTime.utc(2026, 11, 14, 9),
      doctor: false,
    );

    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].path, '/patient/cancel-appointment/21');
    expect(
      (adapter.requests[0].data as Map<String, dynamic>)['reason'],
      'Bận đột xuất',
    );
    expect(adapter.requests[1].method, 'PUT');
    expect(adapter.requests[1].path, '/patient/reschedule-appointment/21');
  });

  testWidgets('doctor completion dialog returns selected bill items', (
    tester,
  ) async {
    final adapter = _StubAdapter(
      (_) => _json({
        'items': [
          {
            'id': 3,
            'name': 'Khám tổng quát',
            'price': 180000,
            'bhytCovered': true,
            'active': true,
          },
          {
            'id': 4,
            'name': 'Soi da',
            'price': 90000,
            'bhytCovered': false,
            'active': true,
          },
        ],
      }),
    );
    _useAdapter(adapter);
    List<int>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showCompleteAppointmentDialog(context)
                      .then((value) => selected = value),
              child: const Text('Mở chẩn đoán'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở chẩn đoán'));
    await tester.pumpAndSettle();

    expect(find.text('Khám tổng quát'), findsOneWidget);
    expect(find.text('180000 ₫ · BHYT'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Hoàn tất'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Khám tổng quát'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    expect(selected, [3]);
    expect(adapter.requests.single.path, '/diseases');
  });

  testWidgets('news feed renders records from the public news contract', (
    tester,
  ) async {
    final adapter = _StubAdapter(
      (request) => _json([
        {
          'id': 5,
          'title': 'Tiêm chủng mùa thu',
          'url': 'https://clinic.example/news/5',
          'createdAt': '2026-11-10T09:00:00Z',
        },
      ]),
    );
    _useAdapter(adapter);

    await tester.pumpWidget(const MaterialApp(home: NewsFeedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tin tức phòng khám'), findsOneWidget);
    expect(find.text('Tiêm chủng mùa thu'), findsOneWidget);
    expect(adapter.requests.single.path, '/news?limit=20');
  });

  testWidgets('admin notifications load unread count and mark all read', (
    tester,
  ) async {
    final adapter = _StubAdapter((request) {
      if (request.path.endsWith('unread-count')) return _json({'count': 2});
      if (request.path.endsWith('read-all')) return _json({'updated': 2});
      return _json([
        {
          'id': 8,
          'title': 'Đã nhận thanh toán',
          'body': 'Lịch #21',
          'readAt': null,
        },
      ]);
    });
    _useAdapter(adapter);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdminNotificationsScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa đọc: 2'), findsOneWidget);
    expect(find.text('Đã nhận thanh toán'), findsOneWidget);
    await tester.tap(find.text('Đánh dấu đã đọc'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.any(
        (request) =>
            request.method == 'POST' &&
            request.path == '/admin/notifications/read-all',
      ),
      isTrue,
    );
  });

  testWidgets(
    'notification unread-count failure is surfaced without crashing',
    (tester) async {
      final adapter = _StubAdapter((request) {
        if (request.path.endsWith('unread-count')) {
          return ResponseBody.fromString('temporarily unavailable', 503);
        }
        return _json([
          {
            'id': 9,
            'title': 'Bản tin vẫn tải được',
            'body': '',
            'readAt': null,
          },
        ]);
      });
      _useAdapter(adapter);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AdminNotificationsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bản tin vẫn tải được'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets('role navigation opens patient profile and admin payments', (
    tester,
  ) async {
    final adapter = _StubAdapter((request) {
      if (request.path == '/news?limit=20') return _json([]);
      if (request.path == '/patient/me') {
        return _json({'name': 'Lan Nguyen'});
      }
      if (request.path.endsWith('unread-count')) return _json({'count': 0});
      if (request.path.startsWith('/admin/')) return _json([]);
      return _json([]);
    });
    _useAdapter(adapter);

    await tester.pumpWidget(const MaterialApp(home: RoleHome(role: 'patient')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ bệnh nhân'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: RoleHome(role: 'admin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thanh toán'));
    await tester.pumpAndSettle();
    expect(find.text('Không có giao dịch'), findsOneWidget);
    expect(
      adapter.requests.any(
        (request) => request.path == '/admin/payments?status=pending',
      ),
      isTrue,
    );
  });

  testWidgets('doctor completes an appointment with selected disease IDs', (
    tester,
  ) async {
    final adapter = _StubAdapter((request) {
      if (request.path == '/doctor/list-appointment') {
        return _json([
          {
            'id': 31,
            'apTime': '2026-11-12T09:00:00.000Z',
            'confirmCondition': 0,
            'address': 'Clinic',
            'doctorName': 'Dr. Nguyen',
            'patientName': 'Lan Nguyen',
          },
        ]);
      }
      if (request.path == '/diseases') {
        return _json({
          'items': [
            {
              'id': 6,
              'name': 'Khám tổng quát',
              'price': 180000,
              'bhytCovered': true,
              'active': true,
            },
          ],
        });
      }
      return _json({'ok': true});
    });
    _useAdapter(adapter);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppointmentsScreen(doctor: true))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã xác nhận'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chẩn đoán và hoàn tất khám'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khám tổng quát'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    final completion = adapter.requests.singleWhere(
      (request) => request.path == '/doctor/complete/31',
    );
    expect(completion.method, 'POST');
    expect((completion.data as Map<String, dynamic>)['diseaseIds'], [6]);
  });

  testWidgets('doctor role navigation opens shift management', (tester) async {
    final adapter = _StubAdapter(
      (request) => _json(request.path.endsWith('shift-templates') ? [] : []),
    );
    _useAdapter(adapter);

    await tester.pumpWidget(const MaterialApp(home: RoleHome(role: 'doctor')));
    await tester.pumpAndSettle();
    expect(find.text('Lịch khám'), findsWidgets);
    await tester.tap(find.text('Ca trực'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký ca'), findsOneWidget);
    expect(
      adapter.requests.any((request) => request.path == '/doctor/my-shifts'),
      isTrue,
    );
    expect(
      adapter.requests.any(
        (request) => request.path == '/doctor/shift-templates',
      ),
      isTrue,
    );
  });

  testWidgets('patient confirms cancellation with a reason', (tester) async {
    final adapter = _StubAdapter(
      (_) => _json([
        {
          'id': 44,
          'apTime': '2026-11-12T09:00:00.000Z',
          'confirmCondition': 1,
          'address': 'Clinic',
          'doctorName': 'Dr. Nguyen',
        },
      ]),
    );
    _useAdapter(adapter);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppointmentsScreen(doctor: false)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy lịch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Không thể đến khám');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    final cancel = adapter.requests.singleWhere(
      (request) => request.path == '/patient/cancel-appointment/44',
    );
    expect(cancel.method, 'POST');
    expect(
      (cancel.data as Map<String, dynamic>)['reason'],
      'Không thể đến khám',
    );
  });

  testWidgets('patient reschedules from detail using an available slot', (
    tester,
  ) async {
    final day = DateTime.now().add(const Duration(days: 1));
    final slot = DateTime(
      day.year,
      day.month,
      day.day,
      10,
      30,
    ).toIso8601String();
    final adapter = _StubAdapter((request) {
      if (request.path == '/patient/appointment/44') {
        return _json({
          'id': 44,
          'apTime': '2026-11-12T09:00:00.000Z',
          'confirmCondition': 1,
          'address': 'Clinic',
          'doctorName': 'Dr. Nguyen',
        });
      }
      if (request.path == '/doctor/availability') return _json([slot]);
      return _json({'ok': true});
    });
    _useAdapter(adapter);

    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentDetailScreen(
          appointment: Appointment(
            id: 44,
            time: DateTime.parse('2026-11-12T09:00:00.000Z'),
            status: 1,
            address: 'Clinic',
            doctorId: 9,
            name: 'Dr. Nguyen',
          ),
          doctor: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ngày đổi lịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ActionChip).first);
    await tester.pumpAndSettle();

    final reschedule = adapter.requests.singleWhere(
      (request) => request.path == '/patient/reschedule-appointment/44',
    );
    expect(reschedule.method, 'PUT');
    expect((reschedule.data as Map<String, dynamic>)['apTime'], isA<String>());
  });
}
