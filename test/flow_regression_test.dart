import 'dart:convert';
import 'dart:typed_data';

import 'package:dacn_app/screens/doctor_shifts_screen.dart';
import 'package:dacn_app/screens/patient_profile_screen.dart';
import 'package:dacn_app/screens/payment_screen.dart';
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
}
