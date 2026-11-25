import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/family_member.dart';
import '../services/cloud_sync_service.dart';
import 'auth_provider.dart';

final familyBoxProvider = Provider<Box<FamilyMember>>((ref) => Hive.box<FamilyMember>('family'));

final familyMembersProvider = StateNotifierProvider<FamilyNotifier, List<FamilyMember>>((ref) {
  return FamilyNotifier(ref);
});

final activeMemberIdProvider = StateProvider<String?>((ref) {
  final members = ref.watch(familyMembersProvider);
  final settingsBox = Hive.box('settings');
  final savedMemberId = settingsBox.get('active_member_id') as String?;
  if (savedMemberId != null && members.any((m) => m.id == savedMemberId)) {
    return savedMemberId;
  }
  final activeUserId = settingsBox.get('active_user_id') as String?;
  if (activeUserId != null && members.any((m) => m.id == activeUserId)) {
    return activeUserId;
  }
  return members.isNotEmpty ? members.first.id : (savedMemberId ?? activeUserId);
});

final activeMemberProvider = Provider<FamilyMember?>((ref) {
  final members = ref.watch(familyMembersProvider);
  final id = ref.watch(activeMemberIdProvider);
  if (members.isNotEmpty) {
    return members.where((m) => m.id == id).firstOrNull ?? members.first;
  }

  // Fallback to active user profile stored in settings box so profile displays on launch
  final settingsBox = Hive.box('settings');
  final activeUserId = settingsBox.get('active_user_id') as String?;
  if (activeUserId != null) {
    final map = settingsBox.get('user_profile_$activeUserId');
    if (map != null) {
      final prof = Map<String, dynamic>.from(map);
      return FamilyMember()
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
    }
  }
  return null;
});

class FamilyNotifier extends StateNotifier<List<FamilyMember>> {
  final Ref ref;
  bool isLoading = false;
  String? error;

  FamilyNotifier(this.ref) : super([]) {
    loadMembers();
  }

  String _resolveUserId() {
    final settingsBox = Hive.box('settings');
    final activeUserId = settingsBox.get('active_user_id') as String?;
    final authState = ref.read(authProvider);
    return activeUserId ?? authState.userId ?? authState.phoneNumber ?? '1';
  }

  Future<void> loadMembers() async {
    final box = ref.read(familyBoxProvider);
    final settingsBox = Hive.box('settings');
    final activeUserId = settingsBox.get('active_user_id') as String?;

    // 1. If box is empty and user profile is saved in settings, restore the primary Self profile immediately
    if (box.isEmpty && activeUserId != null) {
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
        await box.put(selfMember.id, selfMember);
        await box.flush();
      }
    }

    state = box.values.toList();

    final userId = _resolveUserId();
    if (userId.isEmpty || userId == '1') return;

    isLoading = true;
    error = null;
    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      final remoteMembers = await cloudService.fetchFamilyMembers(userId);
      if (mounted && remoteMembers.isNotEmpty) {
        state = remoteMembers;
      }
    } catch (e) {
      if (mounted) {
        error = e.toString();
      }
    } finally {
      if (mounted) {
        isLoading = false;
      }
    }
  }

  Future<FamilyMember?> addMember({
    required String name,
    required int age,
    required String gender,
    required String relationship,
    required String bloodGroup,
    required List<String> chronicConditions,
    required String phone,
    String? caretakerId,
  }) async {
    final userId = _resolveUserId();

    final cloudService = ref.read(cloudSyncServiceProvider);
    final newMember = await cloudService.addFamilyMember(
      userId: userId,
      name: name,
      age: age,
      gender: gender,
      relationship: relationship,
      bloodGroup: bloodGroup,
      chronicConditions: chronicConditions,
      phone: phone,
      caretakerId: caretakerId,
    );

    if (newMember != null) {
      final box = ref.read(familyBoxProvider);
      await box.put(newMember.id, newMember);
      await box.flush();

      // Prevent duplicates in local state by checking ID
      final existingIndex = state.indexWhere((m) => m.id == newMember.id);
      if (existingIndex >= 0) {
        state[existingIndex] = newMember;
        state = [...state];
      } else {
        state = [...state, newMember];
      }
    }

    return newMember;
  }

  Future<void> assignCaretaker(String patientProfileId, String? caretakerProfileId) async {
    final userId = _resolveUserId();

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.assignCaretaker(
      patientProfileId: patientProfileId,
      caretakerProfileId: caretakerProfileId,
      userId: userId,
    );

    // Update local box and state
    final box = ref.read(familyBoxProvider);
    final member = box.get(patientProfileId);
    if (member != null) {
      member.caretakerId = caretakerProfileId;
      await member.save();
      await box.flush();
    }

    state = state.map((m) {
      if (m.id == patientProfileId) {
        m.caretakerId = caretakerProfileId;
      }
      return m;
    }).toList();
  }

  Future<void> deleteMember(String id) async {
    final userId = _resolveUserId();

    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.deleteFamilyMember(userId, id);

    final box = ref.read(familyBoxProvider);
    await box.delete(id);
    await box.flush();

    state = state.where((m) => m.id != id).toList();
  }

  void refresh() {
    final box = ref.read(familyBoxProvider);
    state = box.values.toList();
  }

  void clear() {
    state = [];
  }
}
