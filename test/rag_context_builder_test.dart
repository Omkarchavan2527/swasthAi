import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swasthai/data/models/family_member.dart';
import 'package:swasthai/data/models/medicine.dart';
import 'package:swasthai/data/models/medical_record.dart';
import 'package:swasthai/data/models/health_measurement.dart';
import 'package:swasthai/data/models/scheduled_dose.dart';
import 'package:swasthai/providers/family_provider.dart';
import 'package:swasthai/providers/medicine_provider.dart';
import 'package:swasthai/services/cloud_sync_service.dart';
import 'package:swasthai/services/rag_context_builder.dart';

class FakeCloudSyncService extends CloudSyncService {
  FakeCloudSyncService(super.ref);

  @override
  Future<List<FamilyMember>> fetchFamilyMembers(String userId) async => [];

  @override
  Future<List<Medicine>> fetchMedicines(String profileId) async => [];

  @override
  Future<List<MedicalRecord>> fetchMedicalRecords(String patientId) async => [];

  @override
  Future<List<ScheduledDose>> fetchScheduledDoses(String profileId) async => [];
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('rag_unit_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FamilyMemberAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MedicineAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MedicalRecordAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HealthMeasurementAdapter());

    await Hive.openBox('settings');
    await Hive.openBox<FamilyMember>('family');
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox<MedicalRecord>('records');
    await Hive.openBox<HealthMeasurement>('measurements');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await Hive.box<FamilyMember>('family').clear();
    await Hive.box<Medicine>('medicines').clear();
    await Hive.box<MedicalRecord>('records').clear();
    await Hive.box<HealthMeasurement>('measurements').clear();
    await Hive.box('settings').clear();
  });

  test('RAG Context Builder: Unit test with ProviderContainer', () async {
    final familyBox = Hive.box<FamilyMember>('family');
    final medBox = Hive.box<Medicine>('medicines');
    final recordBox = Hive.box<MedicalRecord>('records');
    final measureBox = Hive.box<HealthMeasurement>('measurements');

    // 1. Seed Member
    final member = FamilyMember()
      ..id = 'mem_1'
      ..name = 'Rajesh Patil'
      ..age = 45
      ..gender = 'Male'
      ..relationship = 'Self'
      ..bloodGroup = 'O+'
      ..chronicConditions = ['Hypertension', 'Type 2 Diabetes']
      ..phone = '+91 9876543210';
    await familyBox.put(member.id, member);
    await familyBox.flush();

    // 2. Seed Medicines
    final med1 = Medicine()
      ..id = 'med_1'
      ..memberId = 'mem_1'
      ..memberName = 'Rajesh Patil'
      ..name = 'Metformin 500mg'
      ..dosage = '1 tablet'
      ..timing = '08:00'
      ..frequency = 'Twice daily'
      ..startDate = '2026-01-01'
      ..endDate = ''
      ..instructions = 'Take after meals'
      ..takenToday = false
      ..scheduledTimes = ['08:00', '20:00']
      ..prescribedBy = 'Dr. Kulkarni';
    await medBox.put(med1.id, med1);
    await medBox.flush();

    // 3. Seed Vitals
    final m1 = HealthMeasurement()
      ..id = 'm_1'
      ..memberId = 'mem_1'
      ..memberName = 'Rajesh Patil'
      ..date = '2026-10-14'
      ..systolicBP = 138
      ..diastolicBP = 88
      ..bloodSugar = 145.0
      ..weight = 74.0
      ..heartRate = 76;
    await measureBox.put(m1.id, m1);

    final m0 = HealthMeasurement()
      ..id = 'm_0'
      ..memberId = 'mem_1'
      ..memberName = 'Rajesh Patil'
      ..date = '2026-10-01'
      ..systolicBP = 130
      ..diastolicBP = 82
      ..bloodSugar = 130.0
      ..weight = 75.0
      ..heartRate = 72;
    await measureBox.put(m0.id, m0);
    await measureBox.flush();

    // 4. Seed Medical Records
    final rec1 = MedicalRecord()
      ..id = 'rec_1'
      ..memberId = 'mem_1'
      ..memberName = 'Rajesh Patil'
      ..type = 'lab_report'
      ..title = 'HbA1c & Lipid Profile'
      ..date = '2026-10-05'
      ..details = 'HbA1c: 7.2%, Serum Creatinine: 1.0 mg/dL'
      ..doctorName = 'Dr. Kulkarni'
      ..hospitalName = 'District Hospital'
      ..diagnosis = 'Type 2 Diabetes mellitus under control'
      ..tags = ['HbA1c', 'Lipid']
      ..attachedFilePaths = ['/storage/hba1c.pdf'];
    await recordBox.put(rec1.id, rec1);
    await recordBox.flush();

    final container = ProviderContainer(
      overrides: [
        cloudSyncServiceProvider.overrideWith((ref) => FakeCloudSyncService(ref)),
      ],
    );

    // Refresh notifiers from local boxes
    container.read(familyMembersProvider.notifier).refresh();
    container.read(medicinesProvider.notifier).loadMedicines('mem_1');
    container.read(activeMemberIdProvider.notifier).state = 'mem_1';

    final generatedContext = RagContextBuilder.buildContext(container);
    final relevantSearchOutput =
        RagContextBuilder.searchRelevantRecords(container, 'Show my latest HbA1c sugar report');

    // Profile assertions
    expect(generatedContext.contains('Rajesh Patil'), isTrue);
    expect(generatedContext.contains('Hypertension, Type 2 Diabetes'), isTrue);
    expect(generatedContext.contains('O+'), isTrue);

    // Medicine assertions
    expect(generatedContext.contains('Metformin 500mg'), isTrue);
    expect(generatedContext.contains('Take after meals'), isTrue);
    expect(generatedContext.contains('Dr. Kulkarni'), isTrue);

    // Vitals & trends assertions
    expect(generatedContext.contains('138/88 mmHg'), isTrue);
    expect(generatedContext.contains('145.0 mg/dL'), isTrue);
    expect(generatedContext.contains('Trend (latest vs previous)'), isTrue);

    // Medical records assertions
    expect(generatedContext.contains('HbA1c & Lipid Profile'), isTrue);
    expect(generatedContext.contains('District Hospital'), isTrue);

    // Keyword retrieval assertions
    expect(relevantSearchOutput.contains('HbA1c & Lipid Profile'), isTrue);
    expect(relevantSearchOutput.contains('lab_report') || relevantSearchOutput.contains('Lab Report'), isTrue);

    container.dispose();
  });
}
