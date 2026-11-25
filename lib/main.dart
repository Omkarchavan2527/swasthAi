import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/models/family_member.dart';
import 'data/models/medicine.dart';
import 'data/models/medical_record.dart';
import 'data/models/health_measurement.dart';
import 'data/models/vaccination.dart';
import 'data/models/doctor_session.dart';
import 'services/notification_service.dart';

const int _kHiveSchemaVersion = 2; // Bump this when models change

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService().init();

  Hive.registerAdapter(FamilyMemberAdapter());
  Hive.registerAdapter(MedicineAdapter());
  Hive.registerAdapter(MedicalRecordAdapter());
  Hive.registerAdapter(HealthMeasurementAdapter());
  Hive.registerAdapter(VaccinationAdapter());
  Hive.registerAdapter(DoctorSessionAdapter());

  // Open settings first to check schema version
  await Hive.openBox('settings');
  final settingsBox = Hive.box('settings');
  final storedVersion = settingsBox.get('hive_schema_version', defaultValue: 0) as int;

  if (storedVersion < _kHiveSchemaVersion) {
    // Schema changed — delete old boxes to prevent LateInitializationError crashes
    // We preserve settings (auth state) but clear model boxes
    await Hive.deleteBoxFromDisk('family');
    await Hive.deleteBoxFromDisk('medicines');
    await Hive.deleteBoxFromDisk('records');
    await Hive.deleteBoxFromDisk('measurements');
    await Hive.deleteBoxFromDisk('vaccinations');
    await Hive.deleteBoxFromDisk('sessions');
    await settingsBox.put('hive_schema_version', _kHiveSchemaVersion);
  }

  await Hive.openBox<FamilyMember>('family');
  await Hive.openBox<Medicine>('medicines');
  await Hive.openBox<MedicalRecord>('records');
  await Hive.openBox<HealthMeasurement>('measurements');
  await Hive.openBox<Vaccination>('vaccinations');
  await Hive.openBox<DoctorSession>('sessions');

  // If user is logged in to cloud, guarantee primary member profile is present in family box
  final isLoggedIn = settingsBox.get('is_logged_in', defaultValue: false);
  final activeUserId = settingsBox.get('active_user_id') as String?;
  final familyBox = Hive.box<FamilyMember>('family');
  if ((isLoggedIn == true || isLoggedIn == 'true' || isLoggedIn == 1) &&
      activeUserId != null &&
      familyBox.isEmpty) {
    final userProfileMap = settingsBox.get('user_profile_$activeUserId');
    if (userProfileMap != null) {
      final prof = Map<String, dynamic>.from(userProfileMap);
      final selfMember = FamilyMember()
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
      await familyBox.put(selfMember.id, selfMember);
      await familyBox.flush();
    }
  }

  runApp(const ProviderScope(child: SwasthAIApp()));
}
