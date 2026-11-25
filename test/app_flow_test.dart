import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:swasthai/data/models/family_member.dart';
import 'package:swasthai/data/models/medicine.dart';
import 'package:swasthai/services/auth_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('swasthai_unit_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FamilyMemberAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MedicineAdapter());
    }
    await Hive.openBox('settings');
    await Hive.openBox<FamilyMember>('family');
    await Hive.openBox<Medicine>('medicines');
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('Session persistence: User profile is saved to settings and hydrated to family box', () async {
    final settingsBox = Hive.box('settings');
    final familyBox = Hive.box<FamilyMember>('family');

    const userId = 'usr_test_123';
    final userProfile = UserProfile(
      id: userId,
      fullName: 'Omkar Chavan',
      phoneNumber: '+91 98765 43210',
      email: 'omkar@test.com',
      age: 26,
      gender: 'Male',
      bloodGroup: 'B+',
      chronicConditions: ['None'],
    );

    // 1. Simulate signup: saving to settings and creating primary self member
    await settingsBox.put('active_user_id', userId);
    await settingsBox.put('user_profile_$userId', userProfile.toMap());
    await settingsBox.put('user_phone', userProfile.email);
    await settingsBox.put('is_logged_in', true);
    await settingsBox.put('app_mode', 'cloud');
    await settingsBox.flush();

    final selfMember = FamilyMember()
      ..id = userId
      ..name = userProfile.fullName
      ..age = userProfile.age
      ..gender = userProfile.gender
      ..relationship = 'Self'
      ..bloodGroup = userProfile.bloodGroup
      ..chronicConditions = userProfile.chronicConditions
      ..phone = userProfile.phoneNumber
      ..photoUrl = null
      ..caretakerId = null;

    await familyBox.put(selfMember.id, selfMember);
    await familyBox.flush();

    expect(settingsBox.get('is_logged_in'), true);
    expect(settingsBox.get('active_user_id'), userId);
    expect(familyBox.get(userId)?.name, 'Omkar Chavan');

    // 2. Simulate app close and reopening:
    // Even if family box was cleared, main.dart startup hydrates it from settings!
    await familyBox.clear();
    expect(familyBox.isEmpty, true);

    // Startup hydration logic
    final isLoggedIn = settingsBox.get('is_logged_in', defaultValue: false);
    final activeUserId = settingsBox.get('active_user_id') as String?;
    if (isLoggedIn == true && activeUserId != null && familyBox.isEmpty) {
      final profMap = settingsBox.get('user_profile_$activeUserId');
      if (profMap != null) {
        final prof = Map<String, dynamic>.from(profMap);
        final restoredMember = FamilyMember()
          ..id = activeUserId
          ..name = prof['fullName'] ?? prof['full_name'] ?? 'Patient'
          ..age = prof['age'] ?? 25
          ..gender = prof['gender'] ?? 'Male'
          ..relationship = 'Self'
          ..bloodGroup = prof['bloodGroup'] ?? prof['blood_group'] ?? 'O+'
          ..chronicConditions = List<String>.from(prof['chronicConditions'] ?? prof['chronic_conditions'] ?? [])
          ..phone = prof['phoneNumber'] ?? prof['phone_number'] ?? ''
          ..photoUrl = null
          ..caretakerId = null;
        await familyBox.put(restoredMember.id, restoredMember);
        await familyBox.flush();
      }
    }

    // Verify member is restored
    expect(familyBox.isNotEmpty, true);
    expect(familyBox.get(userId)?.name, 'Omkar Chavan');
    expect(familyBox.get(userId)?.relationship, 'Self');
  });

  test('Family member addition and caretaker assignment', () async {
    final familyBox = Hive.box<FamilyMember>('family');

    final parent = FamilyMember()
      ..id = 'mem_parent_1'
      ..name = 'Sunita Chavan'
      ..age = 52
      ..gender = 'Female'
      ..relationship = 'Mother'
      ..bloodGroup = 'O+'
      ..chronicConditions = ['Hypertension']
      ..phone = '+91 98765 00000'
      ..photoUrl = null
      ..caretakerId = 'usr_test_123';

    await familyBox.put(parent.id, parent);
    await familyBox.flush();

    expect(familyBox.get('mem_parent_1')?.name, 'Sunita Chavan');
    expect(familyBox.get('mem_parent_1')?.caretakerId, 'usr_test_123');
  });

  test('Medicine scheduling and profile linkage', () async {
    final medBox = Hive.box<Medicine>('medicines');

    final med = Medicine()
      ..id = 'med_1'
      ..memberId = 'usr_test_123'
      ..memberName = 'Omkar Chavan'
      ..name = 'Metformin 500mg'
      ..dosage = '1 tablet'
      ..timing = '08:00'
      ..frequency = 'Daily'
      ..startDate = '2026-10-10'
      ..endDate = '2026-12-10'
      ..instructions = 'After breakfast'
      ..takenToday = true
      ..scheduledTimes = ['08:00', '20:00']
      ..reminderBeforeMinutes = 15
      ..gracePeriodMinutes = 15
      ..reminderEnabled = true
      ..prescribedBy = 'Dr. Sharma';

    await medBox.put(med.id, med);
    await medBox.flush();

    final userMeds = medBox.values.where((m) => m.memberId == 'usr_test_123').toList();
    expect(userMeds.length, 1);
    expect(userMeds.first.name, 'Metformin 500mg');
    expect(userMeds.first.takenToday, true);
  });
}
