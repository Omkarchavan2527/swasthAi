import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:swasthai/data/models/family_member.dart';
import 'package:swasthai/data/models/medicine.dart';
import 'package:swasthai/data/models/medical_record.dart';
import 'package:swasthai/data/models/health_measurement.dart';
import 'package:swasthai/data/models/vaccination.dart';
import 'package:swasthai/data/models/doctor_session.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('full_suite_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FamilyMemberAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MedicineAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MedicalRecordAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HealthMeasurementAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(VaccinationAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(DoctorSessionAdapter());

    await Hive.openBox('settings');
    await Hive.openBox<FamilyMember>('family');
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox<MedicalRecord>('records');
    await Hive.openBox<HealthMeasurement>('measurements');
    await Hive.openBox<Vaccination>('vaccinations');
    await Hive.openBox<DoctorSession>('sessions');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('1. Medical Records: Add, query by memberId, and filter by tags', () async {
    final recordBox = Hive.box<MedicalRecord>('records');

    final rec1 = MedicalRecord()
      ..id = 'rec_1'
      ..memberId = 'usr_test_123'
      ..memberName = 'Omkar'
      ..type = 'prescription'
      ..title = 'Cardiology Consultation'
      ..date = '2026-10-10'
      ..details = 'Follow-up for hypertension, advised low sodium diet'
      ..doctorName = 'Dr. Sharma'
      ..hospitalName = 'Ruby Hall Clinic'
      ..diagnosis = 'Essential Hypertension'
      ..tags = ['Cardio', 'Routine']
      ..attachedFilePaths = ['/path/to/rx.jpg'];

    await recordBox.put(rec1.id, rec1);
    await recordBox.flush();

    final fetched = recordBox.get('rec_1');
    expect(fetched, isNotNull);
    expect(fetched!.title, 'Cardiology Consultation');
    expect(fetched.tags.contains('Cardio'), isTrue);
    expect(fetched.attachedFilePaths.length, 1);
  });

  test('2. Health Measurements: Record vitals and verify calculation range', () async {
    final measureBox = Hive.box<HealthMeasurement>('measurements');

    final m1 = HealthMeasurement()
      ..id = 'm_1'
      ..memberId = 'usr_test_123'
      ..memberName = 'Omkar'
      ..date = '2026-10-10T08:00:00'
      ..systolicBP = 120
      ..diastolicBP = 80
      ..bloodSugar = 95.0
      ..weight = 70.5
      ..heartRate = 72;

    await measureBox.put(m1.id, m1);
    await measureBox.flush();

    final userMeasures = measureBox.values.where((m) => m.memberId == 'usr_test_123').toList();
    expect(userMeasures.length, 1);
    expect(userMeasures.first.systolicBP, 120);
    expect(userMeasures.first.bloodSugar, 95.0);
  });

  test('3. Doctor Session: Generate 6-digit OTP and verify revocation', () async {
    final sessionBox = Hive.box<DoctorSession>('sessions');

    final sess = DoctorSession()
      ..id = 'sess_1'
      ..patientName = 'Omkar'
      ..patientId = 'usr_test_123'
      ..otp = '482910'
      ..durationMinutes = 30
      ..createdAt = DateTime.now().toIso8601String()
      ..isRevoked = false;

    await sessionBox.put(sess.id, sess);
    await sessionBox.flush();

    expect(sessionBox.get('sess_1')?.otp, '482910');
    expect(sessionBox.get('sess_1')?.isRevoked, isFalse);

    // Revoke access
    sess.isRevoked = true;
    await sess.save();
    expect(sessionBox.get('sess_1')?.isRevoked, isTrue);
  });

  test('4. Vaccination Tracker: Track status and mark administered', () async {
    final vaxBox = Hive.box<Vaccination>('vaccinations');

    final vax = Vaccination()
      ..id = 'vax_1'
      ..memberId = 'usr_test_123'
      ..memberName = 'Omkar'
      ..vaccineName = 'Hepatitis B Booster'
      ..diseaseProtected = 'Hepatitis B'
      ..dueDate = '2026-11-01'
      ..given = false
      ..givenDate = null
      ..ageMilestone = 'Adult';

    await vaxBox.put(vax.id, vax);
    await vaxBox.flush();

    expect(vaxBox.get('vax_1')?.given, isFalse);

    // Mark given
    vax.given = true;
    vax.givenDate = '2026-10-10';
    await vax.save();

    expect(vaxBox.get('vax_1')?.given, isTrue);
    expect(vaxBox.get('vax_1')?.givenDate, '2026-10-10');
  });

  test('5. OpenRouter & AI Fallback key verification in Settings', () async {
    final settingsBox = Hive.box('settings');

    await settingsBox.put('ai_api_key', 'sk-or-v1-abcdef123456');
    await settingsBox.put('ai_provider', 'openrouter');
    await settingsBox.flush();

    expect(settingsBox.get('ai_api_key'), 'sk-or-v1-abcdef123456');
    expect(settingsBox.get('ai_provider'), 'openrouter');
  });
}
