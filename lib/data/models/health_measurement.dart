import 'package:hive_flutter/hive_flutter.dart';

part 'health_measurement.g.dart';

@HiveType(typeId: 3)
class HealthMeasurement extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String memberId;
  @HiveField(2) late String memberName;
  @HiveField(3) late String date;
  @HiveField(4) late int systolicBP;
  @HiveField(5) late int diastolicBP;
  @HiveField(6) late double bloodSugar;
  @HiveField(7) late double weight;
  @HiveField(8) late int heartRate;
}
