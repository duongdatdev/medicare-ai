import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../services/api.dart';

class AiReports {
  final _client = Api.instance.client;

  Future<List<Map<String, dynamic>>> diagnoseImage(
    Uint8List bytes,
    String filename,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/ai/diagnose-image',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return _results(response.data);
  }

  Future<List<Map<String, dynamic>>> analyzeSymptoms(String symptoms) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {'symptoms': symptoms},
    );
    return _results(response.data);
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic>? body) =>
      (body?['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

  Future<Uint8List> buildReport({
    required Uint8List image,
    required String filename,
    required String symptoms,
    required int appointmentId,
  }) async {
    final response = await _client.post<dynamic>(
      '/ai/report',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(image, filename: filename),
        'symptoms': symptoms,
        'appointmentId': appointmentId,
      }),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw const FormatException('PDF response không hợp lệ');
  }

  Future<Uint8List> doctorReport(int appointmentId) async {
    final response = await _client.get<dynamic>(
      '/doctor/report/$appointmentId',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw const FormatException('PDF response không hợp lệ');
  }
}
