import 'api.dart';
import '../models/appointment.dart';

class Appointments {
  final _api = Api.instance.client;

  Future<List<Appointment>> patientList() async =>
      _parse(await Api.instance.list('/patient/list-appointment'));

  Future<List<Appointment>> doctorList(int status) async => _parse(
    await Api.instance.list(switch (status) {
      0 => '/doctor/list-appointment',
      2 => '/doctor/list-completed',
      _ => '/doctor/list-unAcpappointment',
    }),
  );

  List<Appointment> _parse(List<dynamic> values) => values
      .map((value) => Appointment.fromJson(value as Map<String, dynamic>))
      .toList();

  Future<void> create({
    required int doctorId,
    required DateTime time,
    required String address,
    String? note,
  }) async {
    await _api.post(
      '/patient/create-appointment',
      data: {
        'doctorId': doctorId,
        'apTime': time.toIso8601String(),
        'address': address,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<void> statusAction(
    String path,
    int id, {
    Map<String, dynamic>? data,
  }) async {
    await _api.post('/$path/$id', data: data ?? {});
  }

  Future<List<Map<String, dynamic>>> doctors() async =>
      (await Api.instance.list('/doctor/list')).cast<Map<String, dynamic>>();

  Future<List<String>> availability(int doctorId, DateTime date) async {
    final response = await _api.get<List<dynamic>>(
      '/doctor/availability',
      queryParameters: {
        'doctorId': doctorId,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );
    return (response.data ?? []).cast<String>();
  }

  Future<void> patientCancel(int id, String reason) async =>
      statusAction('patient/cancel-appointment', id, data: {'reason': reason});
}
