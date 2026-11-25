import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../data/models/family_member.dart';
import '../data/models/medicine.dart';
import '../data/models/medical_record.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final int age;
  final String gender;
  final String bloodGroup;
  final List<String> chronicConditions;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.chronicConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'chronicConditions': chronicConditions,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? map['full_name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone_number'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 25,
      gender: map['gender'] ?? 'Male',
      bloodGroup: map['bloodGroup'] ?? map['blood_group'] ?? 'O+',
      chronicConditions: List<String>.from(map['chronicConditions'] ?? map['chronic_conditions'] ?? []),
    );
  }
}

class AuthService {
  final Ref ref;
  static const String baseUrl = 'https://swasthai-backend-s7md.onrender.com/api/auth';

  AuthService(this.ref);

  Future<UserProfile> signupUser({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String bloodGroup,
    required List<String> chronicConditions,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'chronicConditions': chronicConditions,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorMsg = data['error'] ?? 'Signup failed. Please try again.';
      throw Exception(errorMsg);
    }

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Signup failed.');
    }

    final userData = data['user'];
    final userId = userData['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final userProfile = UserProfile(
      id: userId,
      fullName: userData['full_name'] ?? fullName,
      phoneNumber: userData['phone_number'] ?? phoneNumber,
      email: email,
      age: userData['age'] ?? age,
      gender: userData['gender'] ?? gender,
      bloodGroup: userData['blood_group'] ?? bloodGroup,
      chronicConditions: List<String>.from(userData['chronic_conditions'] ?? chronicConditions),
    );

    // Clear all previous Hive cache to ensure zero cross-account leak
    await Hive.box<FamilyMember>('family').clear();
    await Hive.box<Medicine>('medicines').clear();
    await Hive.box<MedicalRecord>('records').clear();

    // Save to Hive
    final settingsBox = Hive.box('settings');
    await settingsBox.put('active_user_id', userId);
    await settingsBox.put('active_member_id', userId);
    await settingsBox.put('user_profile_$userId', userProfile.toMap());
    await settingsBox.put('user_phone', email);
    await settingsBox.put('is_logged_in', true);
    await settingsBox.put('is_family_member_mode', false);
    await settingsBox.put('app_mode', 'cloud');
    await settingsBox.flush();

    // Create Primary Family Member Profile locally
    final familyBox = Hive.box<FamilyMember>('family');
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

    ref.read(authProvider.notifier).loginCloud(
      email,
      userId: userId,
      isFamilyMode: false,
    );

    // Refresh Family Provider & Active Member
    ref.read(familyMembersProvider.notifier).loadMembers();
    ref.read(activeMemberIdProvider.notifier).state = userId;

    return userProfile;
  }

  Future<UserProfile> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      final errorMsg = data['error'] ?? 'Login failed. Please check credentials.';
      throw Exception(errorMsg);
    }

    final userData = data['user'];
    final userId = userData['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final profile = UserProfile(
      id: userId,
      fullName: userData['full_name'] ?? 'Patient',
      phoneNumber: userData['phone_number'] ?? '',
      email: email,
      age: userData['age'] ?? 30,
      gender: userData['gender'] ?? 'Male',
      bloodGroup: userData['blood_group'] ?? 'O+',
      chronicConditions: List<String>.from(userData['chronic_conditions'] ?? []),
    );

    // Clear all previous Hive cache to guarantee zero cross-account leak
    await Hive.box<FamilyMember>('family').clear();
    await Hive.box<Medicine>('medicines').clear();
    await Hive.box<MedicalRecord>('records').clear();

    final settingsBox = Hive.box('settings');
    await settingsBox.put('active_user_id', userId);
    await settingsBox.put('active_member_id', userId);
    await settingsBox.put('user_profile_$userId', profile.toMap());
    await settingsBox.put('user_phone', email);
    await settingsBox.put('is_logged_in', true);
    await settingsBox.put('is_family_member_mode', false);
    await settingsBox.put('app_mode', 'cloud');
    await settingsBox.flush();

    // Save primary profile in Hive family box so patient profile displays on screen immediately!
    final familyBox = Hive.box<FamilyMember>('family');
    final selfMember = FamilyMember()
      ..id = userId
      ..name = profile.fullName
      ..age = profile.age
      ..gender = profile.gender
      ..relationship = 'Self'
      ..bloodGroup = profile.bloodGroup
      ..chronicConditions = profile.chronicConditions
      ..phone = profile.phoneNumber
      ..photoUrl = null
      ..caretakerId = null;

    await familyBox.put(selfMember.id, selfMember);
    await familyBox.flush();

    ref.read(authProvider.notifier).loginCloud(
      email,
      userId: userId,
      isFamilyMode: false,
    );

    ref.read(familyMembersProvider.notifier).loadMembers();
    ref.read(activeMemberIdProvider.notifier).state = userId;

    return profile;
  }

  /// Login as a Family Member using unique Family Access Code or phone
  Future<FamilyMember> loginFamilyMember({
    required String accessCode,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/family-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessCode': accessCode.trim().toUpperCase(),
        'phone': phone?.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      final errorMsg = data['error'] ?? 'Invalid Family Access Code. Please check the code and try again.';
      throw Exception(errorMsg);
    }

    final m = data['member'];
    final u = data['user'] ?? {};
    final primaryUserId = u['id'] ?? m['userId'] ?? 'usr_family';

    int parseAge(dynamic a) => a is int ? a : (int.tryParse(a?.toString() ?? '') ?? 25);

    final member = FamilyMember()
      ..id = m['id']
      ..name = m['name'] ?? 'Family Member'
      ..age = parseAge(m['age'])
      ..gender = m['gender'] ?? 'Male'
      ..relationship = m['relationship'] ?? 'Family'
      ..bloodGroup = m['bloodGroup'] ?? 'O+'
      ..chronicConditions = List<String>.from(m['chronicConditions'] ?? [])
      ..phone = m['phone'] ?? ''
      ..photoUrl = null
      ..caretakerId = m['caretakerId'];

    // 1. Clear previous user's data from all Hive boxes to guarantee isolation
    await Hive.box<FamilyMember>('family').clear();
    await Hive.box<Medicine>('medicines').clear();
    await Hive.box<MedicalRecord>('records').clear();

    // 2. Save session in settings
    final settingsBox = Hive.box('settings');
    await settingsBox.put('active_user_id', primaryUserId);
    await settingsBox.put('active_member_id', member.id);
    await settingsBox.put('is_family_member_mode', true);
    await settingsBox.put('family_access_code', m['accessCode'] ?? accessCode.toUpperCase());
    await settingsBox.put('family_member_name', member.name);
    await settingsBox.put('user_phone', member.phone.isNotEmpty ? member.phone : primaryUserId);
    await settingsBox.put('is_logged_in', true);
    await settingsBox.put('app_mode', 'cloud');
    await settingsBox.flush();

    // 3. Save member to Hive family box
    final familyBox = Hive.box<FamilyMember>('family');
    await familyBox.put(member.id, member);
    await familyBox.flush();

    // 4. Update AuthProvider
    ref.read(authProvider.notifier).loginCloud(
      member.phone.isNotEmpty ? member.phone : primaryUserId,
      userId: primaryUserId,
      isFamilyMode: true,
      accessCode: m['accessCode'] ?? accessCode.toUpperCase(),
      memberName: member.name,
    );

    // 5. Refresh Riverpod Family Providers
    ref.read(familyMembersProvider.notifier).loadMembers();
    ref.read(activeMemberIdProvider.notifier).state = member.id;

    return member;
  }

  UserProfile? getCurrentUser() {
    final settingsBox = Hive.box('settings');
    final userId = settingsBox.get('active_user_id');
    if (userId != null) {
      final map = settingsBox.get('user_profile_$userId');
      if (map != null) {
        return UserProfile.fromMap(Map<String, dynamic>.from(map));
      }
    }
    return null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});
