import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppMode { demo, cloud }

class AuthState {
  final AppMode mode;
  final String? userId;
  final String? phoneNumber;
  final bool isLoggedIn;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final bool isFamilyMemberMode;
  final String? familyAccessCode;
  final String? familyMemberName;

  AuthState({
    required this.mode,
    this.userId,
    this.phoneNumber,
    required this.isLoggedIn,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.isFamilyMemberMode = false,
    this.familyAccessCode,
    this.familyMemberName,
  });

  AuthState copyWith({
    AppMode? mode,
    String? userId,
    String? phoneNumber,
    bool? isLoggedIn,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    bool? isFamilyMemberMode,
    String? familyAccessCode,
    String? familyMemberName,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      isFamilyMemberMode: isFamilyMemberMode ?? this.isFamilyMemberMode,
      familyAccessCode: familyAccessCode ?? this.familyAccessCode,
      familyMemberName: familyMemberName ?? this.familyMemberName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          mode: AppMode.cloud,
          isLoggedIn: false,
        )) {
    _loadState();
  }

  void _loadState() {
    final box = Hive.box('settings');
    final savedPhone = box.get('user_phone');
    final activeUserId = box.get('active_user_id') as String?;
    final rawLoggedIn = box.get('is_logged_in', defaultValue: false);
    final isLoggedIn = rawLoggedIn == true || rawLoggedIn == 'true' || rawLoggedIn == 1;
    final isFamilyMode = box.get('is_family_member_mode', defaultValue: false) == true;
    final accessCode = box.get('family_access_code') as String?;
    final memberName = box.get('family_member_name') as String?;

    state = state.copyWith(
      mode: AppMode.cloud,
      userId: activeUserId,
      phoneNumber: savedPhone as String?,
      isLoggedIn: isLoggedIn,
      isFamilyMemberMode: isFamilyMode,
      familyAccessCode: accessCode,
      familyMemberName: memberName,
    );
  }

  void loginCloud(
    String phone, {
    String? userId,
    bool isFamilyMode = false,
    String? accessCode,
    String? memberName,
  }) {
    final box = Hive.box('settings');
    box.put('app_mode', 'cloud');
    box.put('user_phone', phone);
    if (userId != null) {
      box.put('active_user_id', userId);
    }
    box.put('is_logged_in', true);
    box.put('is_family_member_mode', isFamilyMode);
    if (accessCode != null) box.put('family_access_code', accessCode);
    if (memberName != null) box.put('family_member_name', memberName);
    box.flush();
    final effectiveUserId = userId ?? box.get('active_user_id') as String?;
    state = state.copyWith(
      mode: AppMode.cloud,
      userId: effectiveUserId,
      phoneNumber: phone,
      isLoggedIn: true,
      lastSyncedAt: DateTime.now(),
      isFamilyMemberMode: isFamilyMode,
      familyAccessCode: accessCode,
      familyMemberName: memberName,
    );
  }

  void loginAsFamilyMember({
    required String memberId,
    required String memberName,
    required String accessCode,
    String? phone,
  }) {
    final box = Hive.box('settings');
    box.put('app_mode', 'cloud');
    box.put('is_logged_in', true);
    box.put('is_family_member_mode', true);
    box.put('active_user_id', memberId);
    box.put('active_member_id', memberId);
    box.put('family_access_code', accessCode);
    box.put('family_member_name', memberName);
    if (phone != null) box.put('user_phone', phone);
    box.flush();

    state = state.copyWith(
      mode: AppMode.cloud,
      userId: memberId,
      phoneNumber: phone ?? state.phoneNumber,
      isLoggedIn: true,
      lastSyncedAt: DateTime.now(),
      isFamilyMemberMode: true,
      familyAccessCode: accessCode,
      familyMemberName: memberName,
    );
  }

  Future<void> logout() async {
    final box = Hive.box('settings');
    box.put('is_logged_in', false);
    box.delete('active_user_id');
    box.delete('user_phone');
    box.delete('active_member_id');
    box.delete('is_family_member_mode');
    box.delete('family_access_code');
    box.delete('family_member_name');
    await box.flush();

    // Clear all Hive boxes to guarantee complete account isolation
    try {
      if (Hive.isBoxOpen('family')) await Hive.box('family').clear();
      if (Hive.isBoxOpen('medicines')) await Hive.box('medicines').clear();
      if (Hive.isBoxOpen('records')) await Hive.box('records').clear();
      if (Hive.isBoxOpen('measurements')) await Hive.box('measurements').clear();
      if (Hive.isBoxOpen('vaccinations')) await Hive.box('vaccinations').clear();
      if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').clear();
    } catch (_) {}

    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      phoneNumber: null,
      isFamilyMemberMode: false,
      familyAccessCode: null,
      familyMemberName: null,
    );
  }

  void setSyncing(bool syncing) {
    state = state.copyWith(
      isSyncing: syncing,
      lastSyncedAt: syncing ? state.lastSyncedAt : DateTime.now(),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
