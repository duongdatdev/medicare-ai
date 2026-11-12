import 'package:dio/dio.dart';

/// Formats an amount in Vietnamese Dong (e.g. 180000 -> "180.000 ₫").
String formatVnd(dynamic value) {
  if (value == null) return '—';
  final amount = value is num
      ? value.round()
      : int.tryParse(value.toString()) ?? 0;
  final negative = amount < 0;
  final digits = amount.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${negative ? '-' : ''}$digits ₫';
}

/// Formats a [DateTime] into local `dd/MM/yyyy · HH:mm`.
String formatDateTime(DateTime? dt, {String fallback = 'Chưa xác định'}) {
  if (dt == null) return fallback;
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} · $h:$min';
}

/// Parses an ISO timestamp (or returns fallback) and formats as local `dd/MM/yyyy · HH:mm`.
String formatIsoDateTime(dynamic raw, {String fallback = '—'}) {
  if (raw == null) return fallback;
  final parsed = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
  if (parsed == null) {
    final text = raw.toString().trim();
    return text.isEmpty ? fallback : text;
  }
  return formatDateTime(parsed, fallback: fallback);
}

/// Formats a [DateTime] as `dd/MM/yyyy`.
String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

/// Formats a [DateTime] as `yyyy-MM-dd` for backend DTOs.
String formatDateApi(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Formats a [DateTime] into local `HH:mm`.
String formatTimeOnly(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

/// Formats a numeric hour count cleanly without noisy trailing zeros.
String formatHours(dynamic value) {
  final hours = (value as num?)?.toDouble() ?? 0;
  if (hours == hours.roundToDouble()) return '${hours.toInt()} giờ';
  return '${hours.toStringAsFixed(1)} giờ';
}

/// Maps backend gender codes (`male`, `female`, `other`) to Vietnamese labels.
String genderLabel(String? gender) => switch (gender) {
  'male' => 'Nam',
  'female' => 'Nữ',
  'other' => 'Khác',
  _ => gender?.trim().isNotEmpty == true ? gender!.trim() : 'Chưa cập nhật',
};

/// Maps backend payment status (`unpaid`, `pending`, `paid`) to Vietnamese labels.
String paymentStatusLabel(String? status) => switch (status) {
  'paid' => 'Đã thanh toán',
  'pending' => 'Chờ xác nhận',
  _ => 'Chưa thanh toán',
};

/// Maps backend payment method (`cash`, `qr`) to Vietnamese labels.
String paymentMethodLabel(String? method) => switch (method) {
  'qr' => 'Chuyển khoản VietQR',
  'cash' => 'Tiền mặt',
  _ => method?.trim().isNotEmpty == true ? method!.trim() : 'Chưa chọn',
};

/// Extracts a human-readable error message from a [DioException] or generic error.
String formatApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is List && msg.isNotEmpty) {
        return msg.map((e) => e.toString()).join(', ');
      }
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ. Vui lòng thử lại.';
    }
    if (error.response?.statusCode != null) {
      return 'Yêu cầu thất bại (${error.response!.statusCode}).';
    }
  }
  final text = error.toString().replaceFirst(RegExp(r'^FormatException:\s*'), '');
  return text.trim().isEmpty ? 'Đã xảy ra lỗi không xác định.' : text;
}

