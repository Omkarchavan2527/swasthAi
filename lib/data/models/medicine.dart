import 'package:hive_flutter/hive_flutter.dart';

part 'medicine.g.dart';

@HiveType(typeId: 1)
class Medicine extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String memberId;
  @HiveField(2) late String memberName;
  @HiveField(3) late String name;
  @HiveField(4) late String dosage;
  @HiveField(5) late String timing;
  @HiveField(6) late String frequency;
  @HiveField(7) late String startDate;
  @HiveField(8) late String endDate;
  @HiveField(9) late String instructions;
  @HiveField(10) late bool takenToday;
  // NOTE: No 'late' on optional new fields to prevent LateInitializationError on old Hive data
  @HiveField(11) List<String> scheduledTimes = const ['08:00'];
  @HiveField(12) int reminderBeforeMinutes = 15;
  @HiveField(13) int gracePeriodMinutes = 15;
  @HiveField(14) bool reminderEnabled = true;
  @HiveField(15) String? prescribedBy;
}
