class Appointment {
  const Appointment({
    required this.id,
    required this.time,
    required this.status,
    required this.address,
    this.name,
    this.note,
    this.doctorId,
    this.rescheduled = false,
    this.cancelReason,
  });

  final int id;
  final DateTime? time;
  final int status;
  final String address;
  final String? name;
  final String? note;
  final int? doctorId;
  final bool rescheduled;
  final String? cancelReason;

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: (json['id'] as num).toInt(),
    time: DateTime.tryParse('${json['apTime'] ?? ''}'),
    status: (json['confirmCondition'] as num?)?.toInt() ?? 1,
    address: json['address'] as String? ?? '',
    name: json['doctorName'] as String? ?? json['patientName'] as String?,
    note: json['note'] as String? ?? json['cancelReason'] as String?,
    doctorId:
        (json['doctorId'] as num?)?.toInt() ??
        ((json['doctor'] as Map<String, dynamic>?)?['id'] as num?)?.toInt(),
    rescheduled: json['rescheduled'] as bool? ?? false,
    cancelReason: json['cancelReason'] as String?,
  );
}
