import 'package:hive_flutter/hive_flutter.dart';

part 'medical_record.g.dart';

@HiveType(typeId: 2)
class MedicalRecord extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String memberId;
  @HiveField(2) late String memberName;
  @HiveField(3) late String type; // 'doctor_visit','lab_report','prescription','xray','mri','photo','vaccination','discharge','history','measurement'
  @HiveField(4) late String title;
  @HiveField(5) late String date;
  @HiveField(6) late String details;
  @HiveField(7) late String? doctorName;
  @HiveField(8) late String? hospitalName;
  @HiveField(9) late String? diagnosis;
  @HiveField(10) late List<String> tags;
  @HiveField(11) late List<String> attachedFilePaths; // local file paths on device
}
