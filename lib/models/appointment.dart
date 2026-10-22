class Appointment {
  const Appointment({
    required this.id,
    required this.time,
    required this.status,
    required this.address,
    this.name,
    this.note,
  });

  final int id;
  final DateTime? time;
  final int status;
  final String address;
  final String? name;
  final String? note;

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: (json['id'] as num).toInt(),
    time: DateTime.tryParse('${json['apTime'] ?? ''}'),
    status: (json['confirmCondition'] as num?)?.toInt() ?? 1,
    address: json['address'] as String? ?? '',
    name: json['doctorName'] as String? ?? json['patientName'] as String?,
    note: json['note'] as String? ?? json['cancelReason'] as String?,
  );
}
