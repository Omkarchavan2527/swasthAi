class ScheduledDose {
  final String id;
  final String medicineId;
  final String profileId;
  final String medicineName;
  final String dosage;
  final String scheduledTime;
  final String scheduledDate;
  final String status; // 'Pending', 'Taken', 'Overdue', 'Missed'
  final String? takenAt;
  final String? instructions;
  final bool escalated;

  ScheduledDose({
    required this.id,
    required this.medicineId,
    required this.profileId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    required this.scheduledDate,
    required this.status,
    this.takenAt,
    this.instructions,
    this.escalated = false,
  });

  bool get isTaken => status.toLowerCase() == 'taken';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  bool get isMissed => status.toLowerCase() == 'missed';
  bool get isPending => status.toLowerCase() == 'pending';

  factory ScheduledDose.fromJson(Map<String, dynamic> json) {
    final med = json['medicines'] ?? {};
    return ScheduledDose(
      id: json['id'] ?? '',
      medicineId: json['medicine_id'] ?? json['medicineId'] ?? '',
      profileId: json['profile_id'] ?? json['profileId'] ?? '',
      medicineName: med['name'] ?? json['medicineName'] ?? json['medicine_name'] ?? 'Medicine',
      dosage: med['dosage'] ?? json['dosage'] ?? '1 tablet',
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'] ?? '08:00',
      scheduledDate: json['scheduled_date'] ?? json['scheduledDate'] ?? '',
      status: json['status'] ?? 'Pending',
      takenAt: json['taken_at'] ?? json['takenAt'],
      instructions: med['instructions'] ?? json['instructions'],
      escalated: json['escalated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'profile_id': profileId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'scheduled_time': scheduledTime,
      'scheduled_date': scheduledDate,
      'status': status,
      'taken_at': takenAt,
      'instructions': instructions,
      'escalated': escalated,
    };
  }
}
