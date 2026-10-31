import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

class Session extends ChangeNotifier {
  Session() : _http = Api.instance.client;

  static const _tokenKey = 'accessToken';
  static const _roleKey = 'role';
  static const _doctorIdKey = 'doctorId';
  final Dio _http;
  String? token;
  String? role;
  int? doctorId;
  bool loading = true;
  bool get signedIn => token != null && role != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    role = prefs.getString(_roleKey);
    doctorId = prefs.getInt(_doctorIdKey);
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
    doctorId = (body?['doctorId'] as num?)?.toInt();
    if (doctorId != null) await prefs.setInt(_doctorIdKey, doctorId!);
    token = accessToken;
    role = accountRole;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_doctorIdKey);
    token = null;
    role = null;
    doctorId = null;
    notifyListeners();
  }
}
