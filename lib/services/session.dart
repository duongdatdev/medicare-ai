import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session extends ChangeNotifier {
  Session()
    : _http = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );

  static const _override = String.fromEnvironment('API_BASE');
  static String get _baseUrl => _override.isNotEmpty
      ? _override
      : kIsWeb || defaultTargetPlatform == TargetPlatform.iOS
      ? 'http://localhost:3000'
      : 'http://10.0.2.2:3000';

  static const _tokenKey = 'accessToken';
  static const _roleKey = 'role';
  final Dio _http;
  String? token;
  String? role;
  bool loading = true;
  bool get signedIn => token != null && role != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    role = prefs.getString(_roleKey);
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final body = response.data;
    final accessToken = body?['accessToken'] as String?;
    final accountRole = body?['role'] as String?;
    if (accessToken == null || accountRole == null) {
      throw const FormatException('Phản hồi đăng nhập không hợp lệ');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_roleKey, accountRole);
    token = accessToken;
    role = accountRole;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    token = null;
    role = null;
    notifyListeners();
  }
}
