class Appointment {
  const Appointment({
    required this.id,
    required this.time,
    required this.status,
    required this.address,
    this.name,
    this.note,
    this.doctorNote,
    this.doctorId,
    this.patientId,
    this.rescheduled = false,
    this.cancelReason,
    this.canceledBy,
    this.paymentStatus,
    this.payable,
    this.avatar,
  });

  final int id;
  final DateTime? time;
  final int status;
  final String address;
  final String? name;
  final String? note;
  final String? doctorNote;
  final int? doctorId;
  final int? patientId;
  final bool rescheduled;
  final String? cancelReason;
  final String? canceledBy;
  final String? paymentStatus;
  final int? payable;
  final String? avatar;

  bool get isCanceled => cancelReason != null && cancelReason!.trim().isNotEmpty;

  factory Appointment.fromJson(
    Map<String, dynamic> json, {
    bool doctor = false,
  }) {
    final relation = json[doctor ? 'patient' : 'doctor'];
    final relationMap = relation is Map<String, dynamic> ? relation : null;
    final relationName = _nonEmpty(relationMap?['name']);
    final primaryName = _nonEmpty(json[doctor ? 'patientName' : 'doctorName']);
    final fallbackName = _nonEmpty(json[doctor ? 'doctorName' : 'patientName']);
    return Appointment(
      id: (json['id'] as num).toInt(),
      time: DateTime.tryParse('${json['apTime'] ?? ''}'),
      status: (json['confirmCondition'] as num?)?.toInt() ?? 1,
      address: json['address'] as String? ?? '',
      name: primaryName ?? relationName ?? fallbackName,
      note: json['note'] as String? ?? json['cancelReason'] as String?,
      doctorNote: _nonEmpty(json['doctorNote']),
      doctorId:
          (json['doctorId'] as num?)?.toInt() ??
          (json['doctor'] is Map<String, dynamic>
              ? ((json['doctor'] as Map<String, dynamic>)['id'] as num?)?.toInt()
              : null),
      patientId:
          (json['patientId'] as num?)?.toInt() ??
          (json['patient'] is Map<String, dynamic>
              ? ((json['patient'] as Map<String, dynamic>)['id'] as num?)?.toInt()
              : null),
      rescheduled: json['rescheduled'] as bool? ?? false,
      cancelReason: _nonEmpty(json['cancelReason']),
      canceledBy: _nonEmpty(json['canceledBy']),
      paymentStatus: _nonEmpty(json['paymentStatus']),
      payable: (json['payable'] as num?)?.toInt(),
      avatar: _nonEmpty(relationMap?['avatar']),
    );
  }

  static String? _nonEmpty(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
