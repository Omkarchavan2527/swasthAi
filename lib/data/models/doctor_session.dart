import 'package:hive_flutter/hive_flutter.dart';

part 'doctor_session.g.dart';

@HiveType(typeId: 5)
class DoctorSession extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String patientName;
  @HiveField(2) late String patientId;
  @HiveField(3) late String otp;
  @HiveField(4) late int durationMinutes;
  @HiveField(5) late String createdAt;
  @HiveField(6) late bool isRevoked;
}
