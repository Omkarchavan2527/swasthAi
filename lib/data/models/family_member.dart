import 'package:hive_flutter/hive_flutter.dart';

part 'family_member.g.dart';

@HiveType(typeId: 0)
class FamilyMember extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late int age;
  @HiveField(3) late String gender; // 'Male'/'Female'/'Other'
  @HiveField(4) late String relationship; // 'Self','Spouse','Son','Daughter','Father','Mother'
  @HiveField(5) late String bloodGroup;
  @HiveField(6) late List<String> chronicConditions;
  @HiveField(7) late String phone;
  @HiveField(8) String? photoUrl;
  // NOTE: No 'late' on optional new fields to prevent LateInitializationError on old Hive data
  @HiveField(9) String? caretakerId;

  /// Deterministic 6-character Family Access Code for mobile login
  String get accessCode {
    if (id.isEmpty) return 'FAM-000000';
    final clean = id.replaceAll(RegExp(r'^(mem_|usr_)'), '').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return 'FAM-${clean.length >= 6 ? clean.substring(0, 6) : clean.padRight(6, 'X')}';
  }
}
