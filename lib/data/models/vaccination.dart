import 'package:hive_flutter/hive_flutter.dart';

part 'vaccination.g.dart';

@HiveType(typeId: 4)
class Vaccination extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String memberId;
  @HiveField(2) late String memberName;
  @HiveField(3) late String vaccineName;
  @HiveField(4) late String diseaseProtected;
  @HiveField(5) late String dueDate;
  @HiveField(6) late bool given;
  @HiveField(7) late String? givenDate;
  @HiveField(8) late String ageMilestone;
}
