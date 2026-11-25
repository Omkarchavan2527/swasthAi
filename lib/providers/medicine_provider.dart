import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/medicine.dart';
import '../data/models/scheduled_dose.dart';
import '../services/cloud_sync_service.dart';
import 'auth_provider.dart';
import 'family_provider.dart';

final medicinesBoxProvider = Provider<Box<Medicine>>((ref) => Hive.box<Medicine>('medicines'));

final medicinesProvider = StateNotifierProvider<MedicineNotifier, List<Medicine>>((ref) {
  return MedicineNotifier(ref);
});

final activeMemberMedicinesProvider = Provider<List<Medicine>>((ref) {
  final allMedicines = ref.watch(medicinesProvider);
  final activeMemberId = ref.watch(activeMemberIdProvider);
  if (activeMemberId == null) return [];
  return allMedicines.where((m) => m.memberId == activeMemberId).toList();
});

final activeScheduledDosesProvider = StateNotifierProvider<ScheduledDosesNotifier, List<ScheduledDose>>((ref) {
  final activeMemberId = ref.watch(activeMemberIdProvider);
  return ScheduledDosesNotifier(ref, activeMemberId);
});

class MedicineNotifier extends StateNotifier<List<Medicine>> {
  final Ref ref;

  MedicineNotifier(this.ref) : super(Hive.box<Medicine>('medicines').values.toList()) {
    ref.listen<String?>(activeMemberIdProvider, (previous, next) {
      if (next != null) {
        loadMedicines(next);
      }
    });
    loadMedicines();
  }

  Future<void> loadMedicines([String? profileId]) async {
    final box = ref.read(medicinesBoxProvider);
    state = box.values.toList();

    final activeMemberId = profileId ?? ref.read(activeMemberIdProvider);
    if (activeMemberId == null) return;

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.fetchMedicines(activeMemberId);
    if (!mounted) return;
    state = box.values.toList();
  }

  Future<void> addMedicine({
    required String name,
    required String dosage,
    required String frequency,
    required List<String> scheduledTimes,
    required int reminderBeforeMinutes,
    required int gracePeriodMinutes,
    required String instructions,
  }) async {
    final activeMemberId = ref.read(activeMemberIdProvider);
    if (activeMemberId == null) return;

    final settingsBox = Hive.box('settings');
    final activeUserId = settingsBox.get('active_user_id') as String?;
    final authState = ref.read(authProvider);
    final userId = activeUserId ?? authState.userId ?? authState.phoneNumber ?? '1';

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.addMedicine(
      profileId: activeMemberId,
      userId: userId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      scheduledTimes: scheduledTimes,
      reminderBeforeMinutes: reminderBeforeMinutes,
      gracePeriodMinutes: gracePeriodMinutes,
      instructions: instructions,
    );

    final box = ref.read(medicinesBoxProvider);
    state = box.values.toList();
    ref.read(activeScheduledDosesProvider.notifier).loadDoses();
  }

  Future<void> deleteMedicine(String id) async {
    final activeMemberId = ref.read(activeMemberIdProvider);
    if (activeMemberId == null) return;

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.deleteMedicine(activeMemberId, id);

    final box = ref.read(medicinesBoxProvider);
    state = box.values.toList();
    ref.read(activeScheduledDosesProvider.notifier).loadDoses();
  }
}

class ScheduledDosesNotifier extends StateNotifier<List<ScheduledDose>> {
  final Ref ref;
  final String? profileId;

  ScheduledDosesNotifier(this.ref, this.profileId) : super([]) {
    loadDoses();
  }

  Future<void> loadDoses() async {
    if (profileId == null) return;
    final cloudService = ref.read(cloudSyncServiceProvider);
    var doses = await cloudService.fetchScheduledDoses(profileId!);
    if (!mounted) return;

    // If backend returned no doses, synthesize from active medicines for this profile
    if (doses.isEmpty) {
      final meds = ref.read(medicinesBoxProvider).values.where((m) => m.memberId == profileId).toList();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final synth = <ScheduledDose>[];
      for (var m in meds) {
        for (var t in m.scheduledTimes) {
          synth.add(ScheduledDose(
            id: 'dose_${m.id}_${t.replaceAll(':', '')}_$todayStr',
            medicineId: m.id,
            profileId: profileId!,
            medicineName: m.name,
            dosage: m.dosage,
            scheduledTime: t,
            scheduledDate: todayStr,
            status: 'Pending',
            instructions: m.instructions,
          ));
        }
      }
      doses = synth;
    }

    // Hydrate taken statuses recorded locally
    final settingsBox = Hive.box('settings');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final takenMap = Map<String, dynamic>.from(settingsBox.get('taken_doses_${profileId}_$todayStr', defaultValue: {}));

    state = doses.map((d) {
      if (d.isTaken || takenMap[d.id] == true || takenMap['${d.medicineId}_${d.scheduledTime}'] == true) {
        return ScheduledDose(
          id: d.id,
          medicineId: d.medicineId,
          profileId: d.profileId,
          medicineName: d.medicineName,
          dosage: d.dosage,
          scheduledTime: d.scheduledTime,
          scheduledDate: d.scheduledDate,
          status: 'Taken',
          takenAt: d.takenAt ?? DateTime.now().toIso8601String(),
          instructions: d.instructions,
          escalated: false,
        );
      }
      return d;
    }).toList();
  }

  Future<void> markDoseTaken(String doseId) async {
    if (profileId == null) return;
    final nowStr = DateTime.now().toIso8601String();
    final todayStr = nowStr.substring(0, 10);

    final dose = state.where((d) => d.id == doseId).firstOrNull;

    // Persist to local settings so it survives refresh & relaunch
    final settingsBox = Hive.box('settings');
    final takenMap = Map<String, dynamic>.from(settingsBox.get('taken_doses_${profileId}_$todayStr', defaultValue: {}));
    takenMap[doseId] = true;
    if (dose != null) {
      takenMap['${dose.medicineId}_${dose.scheduledTime}'] = true;
    }
    await settingsBox.put('taken_doses_${profileId}_$todayStr', takenMap);

    // Optimistic UI update
    state = state.map((d) {
      if (d.id == doseId) {
        return ScheduledDose(
          id: d.id,
          medicineId: d.medicineId,
          profileId: d.profileId,
          medicineName: d.medicineName,
          dosage: d.dosage,
          scheduledTime: d.scheduledTime,
          scheduledDate: d.scheduledDate,
          status: 'Taken',
          takenAt: nowStr,
          instructions: d.instructions,
          escalated: false,
        );
      }
      return d;
    }).toList();

    // Check if all doses for today are completed to record adherence streak
    final allDone = state.isNotEmpty && state.every((d) => d.isTaken);
    if (allDone) {
      final streakDates = List<String>.from(settingsBox.get('streak_dates_$profileId', defaultValue: []));
      if (!streakDates.contains(todayStr)) {
        streakDates.add(todayStr);
        await settingsBox.put('streak_dates_$profileId', streakDates);
      }
    }

    // Send confirmation to backend
    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      await cloudService.markDoseTaken(doseId, profileId!);
    } catch (_) {}
  }

  Future<void> unmarkDoseTaken(String doseId) async {
    if (profileId == null) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final dose = state.where((d) => d.id == doseId).firstOrNull;

    final settingsBox = Hive.box('settings');
    final takenMap = Map<String, dynamic>.from(settingsBox.get('taken_doses_${profileId}_$todayStr', defaultValue: {}));
    takenMap.remove(doseId);
    if (dose != null) {
      takenMap.remove('${dose.medicineId}_${dose.scheduledTime}');
    }
    await settingsBox.put('taken_doses_${profileId}_$todayStr', takenMap);

    state = state.map((d) {
      if (d.id == doseId) {
        return ScheduledDose(
          id: d.id,
          medicineId: d.medicineId,
          profileId: d.profileId,
          medicineName: d.medicineName,
          dosage: d.dosage,
          scheduledTime: d.scheduledTime,
          scheduledDate: d.scheduledDate,
          status: 'Pending',
          takenAt: null,
          instructions: d.instructions,
          escalated: false,
        );
      }
      return d;
    }).toList();
  }

  Future<void> toggleDose(String doseId) async {
    final dose = state.where((d) => d.id == doseId).firstOrNull;
    if (dose == null) return;
    if (dose.isTaken) {
      await unmarkDoseTaken(doseId);
    } else {
      await markDoseTaken(doseId);
    }
  }
}
