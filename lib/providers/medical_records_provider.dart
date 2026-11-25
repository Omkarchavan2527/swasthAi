import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/medical_record.dart';
import '../services/cloud_sync_service.dart';
import 'auth_provider.dart';
import 'family_provider.dart';

final recordsBoxProvider = Provider<Box<MedicalRecord>>((ref) => Hive.box<MedicalRecord>('records'));

final recordsProvider = StateNotifierProvider<RecordsNotifier, List<MedicalRecord>>((ref) {
  return RecordsNotifier(ref);
});

final activeMemberRecordsProvider = Provider<List<MedicalRecord>>((ref) {
  final allRecords = ref.watch(recordsProvider);
  final activeMemberId = ref.watch(activeMemberIdProvider);
  if (activeMemberId == null) return allRecords;
  return allRecords.where((r) => r.memberId == activeMemberId).toList();
});

class RecordsNotifier extends StateNotifier<List<MedicalRecord>> {
  final Ref ref;

  RecordsNotifier(this.ref) : super(Hive.box<MedicalRecord>('records').values.toList()) {
    ref.listen<String?>(activeMemberIdProvider, (previous, next) {
      if (next != null) {
        loadRecords(next);
      }
    });
    loadRecords();
  }

  Future<void> loadRecords([String? patientId]) async {
    final activeId = patientId ?? ref.read(activeMemberIdProvider);
    final box = ref.read(recordsBoxProvider);
    state = box.values.toList();
    if (activeId == null) return;

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.fetchMedicalRecords(activeId);
    if (!mounted) return;
    state = box.values.toList();
  }

  Future<void> addRecord(MedicalRecord r) async {
    final box = ref.read(recordsBoxProvider);
    await box.put(r.id, r);
    await box.flush();
    state = box.values.toList();

    // Persist to Cloud Database (Supabase)
    try {
      final settingsBox = Hive.box('settings');
      final activeUserId = settingsBox.get('active_user_id') as String?;
      final authState = ref.read(authProvider);
      final userId = activeUserId ?? authState.userId ?? authState.phoneNumber ?? r.memberId;

      final cloudService = ref.read(cloudSyncServiceProvider);
      final filePath = r.attachedFilePaths.isNotEmpty ? r.attachedFilePaths.first : null;
      final isLocalFile = filePath != null && !filePath.startsWith('http://') && !filePath.startsWith('https://');

      MedicalRecord? synced;
      if (isLocalFile) {
        synced = await cloudService.uploadMedicalRecordWithFile(
          patientId: r.memberId,
          userId: userId,
          title: r.title,
          type: r.type,
          date: r.date,
          details: r.details,
          doctorName: r.doctorName,
          hospitalName: r.hospitalName,
          filePath: filePath,
        );
      } else {
        synced = await cloudService.addMedicalRecord(
          patientId: r.memberId,
          userId: userId,
          title: r.title,
          type: r.type,
          date: r.date,
          details: r.details,
          doctorName: r.doctorName,
          hospitalName: r.hospitalName,
          diagnosis: r.diagnosis,
          tags: r.tags,
          fileUrl: filePath,
        );
      }

      if (synced != null) {
        if (synced.id != r.id) {
          await box.delete(r.id);
        }
        await box.put(synced.id, synced);
        await box.flush();
        state = box.values.toList();
      }
    } catch (_) {}
  }

  Future<void> deleteRecord(String patientId, String id) async {
    final box = ref.read(recordsBoxProvider);
    await box.delete(id);
    await box.flush();
    state = box.values.toList();

    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      await cloudService.deleteMedicalRecord(patientId, id);
    } catch (_) {}
  }

  void refresh() {
    state = ref.read(recordsBoxProvider).values.toList();
  }
}
