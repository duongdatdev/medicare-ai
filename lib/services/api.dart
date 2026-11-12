import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  Api._() {
    const override = String.fromEnvironment('API_BASE');
    final baseUrl = override.isNotEmpty
        ? override
        : kIsWeb || defaultTargetPlatform == TargetPlatform.iOS
        ? 'http://localhost:3000'
        : 'http://10.0.2.2:3000';
    client = Dio(BaseOptions(baseUrl: baseUrl));
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  static final instance = Api._();
  late final Dio client;

  /// Resolves relative upload paths (e.g. `/uploads/...`) against [client.options.baseUrl].
  String? resolveUrl(String? path) {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = client.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final rel = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$rel';
  }

  Future<List<dynamic>> list(String path) async {
    final response = await client.get(path);
    if (response.data is! List) {
      throw const FormatException('Danh sách không hợp lệ');
    }
    return response.data as List<dynamic>;
  }
}
