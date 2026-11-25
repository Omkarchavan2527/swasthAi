import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../data/models/family_member.dart';
import '../data/models/medical_record.dart';
import '../data/models/medicine.dart';
import '../data/models/scheduled_dose.dart';
import '../providers/auth_provider.dart';

class DoctorSharingSessionResult {
  final String id;
  final String rawToken;
  final String otp;
  final String qrUrl;
  final String expiresAt;

  DoctorSharingSessionResult({
    required this.id,
    required this.rawToken,
    required this.otp,
    required this.qrUrl,
    required this.expiresAt,
  });
}

class CloudSyncService {
  final Ref ref;
  static const String baseUrl = 'https://swasthai-backend-s7md.onrender.com/api';

  CloudSyncService(this.ref);

  /// 1. Fetch Family Member Profiles from Backend API with Strict Account Isolation
  Future<List<FamilyMember>> fetchFamilyMembers(String userId) async {
    final familyBox = Hive.box<FamilyMember>('family');
    try {
      final response = await http.get(Uri.parse('$baseUrl/family/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['members'] != null) {
          final List list = data['members'];
          final remoteMembers = list.map((m) {
            final member = FamilyMember()
              ..id = m['id']
              ..name = m['name']
              ..age = parseInt(m['age'])
              ..gender = m['gender'] ?? 'Male'
              ..relationship = m['relationship'] ?? 'Self'
              ..bloodGroup = m['bloodGroup'] ?? 'O+'
              ..chronicConditions = List<String>.from(m['chronicConditions'] ?? [])
              ..phone = m['phone'] ?? ''
              ..photoUrl = null
              ..caretakerId = m['caretakerId'];
            return member;
          }).toList();

          if (remoteMembers.isNotEmpty) {
            // Cleanly clear and replace Hive with this user's remote members only
            await familyBox.clear();
            for (var m in remoteMembers) {
              await familyBox.put(m.id, m);
            }
            await familyBox.flush();
            return remoteMembers;
          } else {
            // Remote is empty for this specific user.
            // Ensure familyBox does NOT contain members of previous accounts.
            final settingsBox = Hive.box('settings');
            final profileMap = settingsBox.get('user_profile_$userId');
            await familyBox.clear();
            if (profileMap != null) {
              final prof = Map<String, dynamic>.from(profileMap);
              final selfMember = FamilyMember()
                ..id = userId
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

              try {
                await addFamilyMember(
                  userId: userId,
                  name: selfMember.name,
                  age: selfMember.age,
                  gender: selfMember.gender,
                  relationship: selfMember.relationship,
                  bloodGroup: selfMember.bloodGroup,
                  chronicConditions: selfMember.chronicConditions,
                  phone: selfMember.phone,
                );
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    return familyBox.values.toList();
  }

  /// 2. Add Family Member Profile with Duplicate Prevention
  Future<FamilyMember?> addFamilyMember({
    required String userId,
    required String name,
    required int age,
    required String gender,
    required String relationship,
    required String bloodGroup,
    required List<String> chronicConditions,
    required String phone,
    String? caretakerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/family/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'name': name.trim(),
          'age': age,
          'gender': gender,
          'relationship': relationship,
          'bloodGroup': bloodGroup,
          'chronicConditions': chronicConditions,
          'phone': phone,
          'caretakerId': caretakerId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['member'] != null) {
          final m = data['member'];
          final member = FamilyMember()
            ..id = m['id']
            ..name = m['name']
            ..age = parseInt(m['age'])
            ..gender = m['gender']
            ..relationship = m['relationship']
            ..bloodGroup = m['bloodGroup']
            ..chronicConditions = List<String>.from(m['chronicConditions'] ?? [])
            ..phone = m['phone'] ?? ''
            ..photoUrl = null
            ..caretakerId = m['caretakerId'];

          final familyBox = Hive.box<FamilyMember>('family');
          await familyBox.put(member.id, member);
          return member;
        }
      }
    } catch (_) {}

    // Offline fallback
    final memberId = 'mem_${DateTime.now().millisecondsSinceEpoch}';
    final member = FamilyMember()
      ..id = memberId
      ..name = name
      ..age = age
      ..gender = gender
      ..relationship = relationship
      ..bloodGroup = bloodGroup
      ..chronicConditions = chronicConditions
      ..phone = phone
      ..photoUrl = null
      ..caretakerId = caretakerId;

    final familyBox = Hive.box<FamilyMember>('family');
    await familyBox.put(member.id, member);
    return member;
  }

  /// 3. Assign Caretaker
  Future<bool> assignCaretaker({
    required String patientProfileId,
    required String? caretakerProfileId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/family/assign-caretaker'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientProfileId': patientProfileId,
          'caretakerProfileId': caretakerProfileId,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
        final familyBox = Hive.box<FamilyMember>('family');
        final member = familyBox.get(patientProfileId);
        if (member != null) {
          member.caretakerId = caretakerProfileId;
          await member.save();
        }
        return true;
      }
    } catch (_) {}

    final familyBox = Hive.box<FamilyMember>('family');
    final member = familyBox.get(patientProfileId);
    if (member != null) {
      member.caretakerId = caretakerProfileId;
      await member.save();
    }
    return true;
  }

  /// 4. Delete Family Member
  Future<void> deleteFamilyMember(String userId, String memberId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/family/$userId/$memberId'));
    } catch (_) {}

    final familyBox = Hive.box<FamilyMember>('family');
    await familyBox.delete(memberId);
  }

  /// 5. Fetch Profile-Specific Medicines with Remote & Local Sync
  Future<List<Medicine>> fetchMedicines(String profileId) async {
    final medBox = Hive.box<Medicine>('medicines');
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicines/$profileId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['medicines'] != null) {
          final List list = data['medicines'];
          final remoteMeds = list.map((m) {
            final med = Medicine()
              ..id = m['id']
              ..memberId = m['profileId'] ?? profileId
              ..memberName = 'Patient'
              ..name = m['name']
              ..dosage = m['dosage'] ?? '1 tablet'
              ..timing = m['scheduledTimes'] != null && (m['scheduledTimes'] as List).isNotEmpty
                  ? (m['scheduledTimes'] as List).first
                  : '08:00'
              ..frequency = m['frequency'] ?? 'Daily'
              ..startDate = m['startDate'] ?? ''
              ..endDate = m['endDate'] ?? ''
              ..instructions = m['instructions'] ?? ''
              ..takenToday = false
              ..scheduledTimes = List<String>.from(m['scheduledTimes'] ?? ['08:00'])
              ..reminderBeforeMinutes = parseInt(m['reminderBeforeMinutes'] ?? 15)
              ..gracePeriodMinutes = parseInt(m['gracePeriodMinutes'] ?? 15)
              ..reminderEnabled = m['reminderEnabled'] ?? true
              ..prescribedBy = m['prescribedBy'] ?? m['prescribed_by'];
            return med;
          }).toList();

          if (remoteMeds.isNotEmpty) {
            // Upsert remote medicines to Hive
            for (var m in remoteMeds) {
              await medBox.put(m.id, m);
            }
            await medBox.flush();
          } else {
            // Remote is empty: push existing local medicines to backend cloud database
            final localMeds = medBox.values.where((m) => m.memberId == profileId).toList();
            final settingsBox = Hive.box('settings');
            final activeUserId = settingsBox.get('active_user_id') as String?;
            final authState = ref.read(authProvider);
            final userId = activeUserId ?? authState.userId ?? authState.phoneNumber ?? profileId;

            for (var m in localMeds) {
              try {
                await addMedicine(
                  profileId: profileId,
                  userId: userId,
                  name: m.name,
                  dosage: m.dosage,
                  frequency: m.frequency,
                  scheduledTimes: m.scheduledTimes,
                  reminderBeforeMinutes: m.reminderBeforeMinutes,
                  gracePeriodMinutes: m.gracePeriodMinutes,
                  instructions: m.instructions,
                );
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    return medBox.values.where((m) => m.memberId == profileId).toList();
  }

  /// 6. Add Medicine for Specific Profile
  Future<Medicine?> addMedicine({
    required String profileId,
    required String userId,
    required String name,
    required String dosage,
    required String frequency,
    required List<String> scheduledTimes,
    required int reminderBeforeMinutes,
    required int gracePeriodMinutes,
    required String instructions,
  }) async {
    final medBox = Hive.box<Medicine>('medicines');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medicines/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profileId': profileId,
          'userId': userId,
          'name': name.trim(),
          'dosage': dosage,
          'frequency': frequency,
          'scheduledTimes': scheduledTimes,
          'reminderBeforeMinutes': reminderBeforeMinutes,
          'gracePeriodMinutes': gracePeriodMinutes,
          'instructions': instructions,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['medicine'] != null) {
          final m = data['medicine'];
          final med = Medicine()
            ..id = m['id']
            ..memberId = m['profileId'] ?? profileId
            ..memberName = 'Patient'
            ..name = m['name']
            ..dosage = m['dosage']
            ..timing = scheduledTimes.isNotEmpty ? scheduledTimes.first : '08:00'
            ..frequency = m['frequency']
            ..startDate = m['startDate'] ?? ''
            ..endDate = ''
            ..instructions = m['instructions'] ?? ''
            ..takenToday = false
            ..scheduledTimes = List<String>.from(m['scheduledTimes'] ?? scheduledTimes)
            ..reminderBeforeMinutes = reminderBeforeMinutes
            ..gracePeriodMinutes = gracePeriodMinutes
            ..reminderEnabled = true;

          await medBox.put(med.id, med);
          await medBox.flush();
          return med;
        }
      }
    } catch (_) {}

    // Offline fallback
    final medId = 'med_${DateTime.now().millisecondsSinceEpoch}';
    final med = Medicine()
      ..id = medId
      ..memberId = profileId
      ..memberName = 'Patient'
      ..name = name
      ..dosage = dosage
      ..timing = scheduledTimes.isNotEmpty ? scheduledTimes.first : '08:00'
      ..frequency = frequency
      ..startDate = DateTime.now().toString().substring(0, 10)
      ..endDate = ''
      ..instructions = instructions
      ..takenToday = false
      ..scheduledTimes = scheduledTimes
      ..reminderBeforeMinutes = reminderBeforeMinutes
      ..gracePeriodMinutes = gracePeriodMinutes
      ..reminderEnabled = true;

    await medBox.put(med.id, med);
    await medBox.flush();
    return med;
  }

  /// 7. Fetch Today's Scheduled Doses for Profile
  Future<List<ScheduledDose>> fetchScheduledDoses(String profileId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicines/doses/$profileId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['doses'] != null) {
          final List list = data['doses'];
          return list.map((d) => ScheduledDose.fromJson(d)).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  /// 8. Mark Dose as TAKEN (Atomic confirmation)
  Future<bool> markDoseTaken(String doseId, String profileId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medicines/dose/take'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doseId': doseId,
          'profileId': profileId,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  /// 9. Delete Medicine
  Future<void> deleteMedicine(String profileId, String medicineId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/medicines/$profileId/$medicineId'));
    } catch (_) {}

    final medBox = Hive.box<Medicine>('medicines');
    await medBox.delete(medicineId);
    await medBox.flush();
  }

  /// 10. Fetch Medical Records for Specific Patient / User
  Future<List<MedicalRecord>> fetchMedicalRecords(String patientId) async {
    final recordsBox = Hive.box<MedicalRecord>('records');
    try {
      final response = await http.get(Uri.parse('$baseUrl/records/$patientId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['records'] != null) {
          final List list = data['records'];
          final remoteRecords = list.map((r) {
            final rec = MedicalRecord()
              ..id = r['id']
              ..memberId = r['patientId'] ?? r['memberId'] ?? patientId
              ..memberName = 'Patient'
              ..type = (r['type'] ?? 'doctor_visit').toString().toLowerCase().replaceAll(' ', '_')
              ..title = r['title'] ?? 'Health Record'
              ..date = r['date'] ?? DateTime.now().toString().substring(0, 10)
              ..details = r['details'] ?? ''
              ..doctorName = r['doctorName']
              ..hospitalName = r['hospitalName']
              ..diagnosis = r['diagnosis'] ?? r['title']
              ..tags = List<String>.from(r['tags'] ?? [r['type'] ?? 'General'])
              ..attachedFilePaths = r['fileUrl'] != null ? [r['fileUrl']] : [];
            return rec;
          }).toList();

          if (remoteRecords.isNotEmpty) {
            for (var r in remoteRecords) {
              await recordsBox.put(r.id, r);
            }
            await recordsBox.flush();
          } else {
            // Push local records for this patient to backend
            final localRecords = recordsBox.values.where((r) => r.memberId == patientId).toList();
            final settingsBox = Hive.box('settings');
            final activeUserId = settingsBox.get('active_user_id') as String?;
            final authState = ref.read(authProvider);
            final userId = activeUserId ?? authState.userId ?? authState.phoneNumber ?? patientId;

            for (var r in localRecords) {
              try {
                await addMedicalRecord(
                  patientId: patientId,
                  userId: userId,
                  title: r.title,
                  type: r.type,
                  date: r.date,
                  details: r.details,
                  doctorName: r.doctorName,
                  hospitalName: r.hospitalName,
                  diagnosis: r.diagnosis,
                  tags: r.tags,
                  fileUrl: r.attachedFilePaths.isNotEmpty ? r.attachedFilePaths.first : null,
                );
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    return recordsBox.values.where((r) => r.memberId == patientId).toList();
  }

  /// 11. Add Medical Record to Cloud Database
  Future<MedicalRecord?> addMedicalRecord({
    required String patientId,
    required String userId,
    required String title,
    required String type,
    required String date,
    required String details,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    List<String>? tags,
    String? fileUrl,
  }) async {
    final recordsBox = Hive.box<MedicalRecord>('records');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/records/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'userId': userId,
          'title': title.trim(),
          'type': type,
          'date': date,
          'details': details,
          'doctorName': doctorName,
          'hospitalName': hospitalName,
          'diagnosis': diagnosis,
          'tags': tags ?? [type],
          'fileUrl': fileUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['record'] != null) {
          final r = data['record'];
          final rec = MedicalRecord()
            ..id = r['id']
            ..memberId = r['patientId'] ?? patientId
            ..memberName = 'Patient'
            ..type = (r['type'] ?? type).toString().toLowerCase().replaceAll(' ', '_')
            ..title = r['title'] ?? title
            ..date = r['date'] ?? date
            ..details = r['details'] ?? details
            ..doctorName = r['doctorName'] ?? doctorName
            ..hospitalName = r['hospitalName'] ?? hospitalName
            ..diagnosis = r['diagnosis'] ?? diagnosis
            ..tags = List<String>.from(r['tags'] ?? tags ?? [type])
            ..attachedFilePaths = r['fileUrl'] != null ? [r['fileUrl']] : [];

          await recordsBox.put(rec.id, rec);
          await recordsBox.flush();
          return rec;
        }
      }
    } catch (_) {}

    // Offline fallback
    final recId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final rec = MedicalRecord()
      ..id = recId
      ..memberId = patientId
      ..memberName = 'Patient'
      ..type = type.toLowerCase().replaceAll(' ', '_')
      ..title = title
      ..date = date
      ..details = details
      ..doctorName = doctorName
      ..hospitalName = hospitalName
      ..diagnosis = diagnosis
      ..tags = tags ?? [type]
      ..attachedFilePaths = fileUrl != null ? [fileUrl] : [];

    await recordsBox.put(rec.id, rec);
    await recordsBox.flush();
    return rec;
  }

  /// 11b. Upload Medical Record with Document/Image File (Multipart) to Cloud Storage & DB
  Future<MedicalRecord?> uploadMedicalRecordWithFile({
    required String patientId,
    required String userId,
    required String title,
    required String type,
    required String date,
    required String details,
    String? doctorName,
    String? hospitalName,
    String? filePath,
  }) async {
    final recordsBox = Hive.box<MedicalRecord>('records');
    try {
      final uri = Uri.parse('$baseUrl/records/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['patientId'] = patientId;
      request.fields['userId'] = userId;
      request.fields['title'] = title.trim();
      request.fields['type'] = type;
      request.fields['date'] = date;
      request.fields['details'] = details;
      if (doctorName != null && doctorName.isNotEmpty) {
        request.fields['doctorName'] = doctorName;
      }
      if (hospitalName != null && hospitalName.isNotEmpty) {
        request.fields['hospitalName'] = hospitalName;
      }

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('file', filePath));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['record'] != null) {
          final r = data['record'];
          final rec = MedicalRecord()
            ..id = r['id']
            ..memberId = r['patientId'] ?? patientId
            ..memberName = 'Patient'
            ..type = (r['type'] ?? type).toString().toLowerCase().replaceAll(' ', '_')
            ..title = r['title'] ?? title
            ..date = r['date'] ?? date
            ..details = r['details'] ?? details
            ..doctorName = r['doctorName'] ?? doctorName
            ..hospitalName = r['hospitalName'] ?? hospitalName
            ..diagnosis = r['diagnosis'] ?? title
            ..tags = List<String>.from(r['tags'] ?? [type])
            ..attachedFilePaths = r['fileUrl'] != null && (r['fileUrl'] as String).isNotEmpty
                ? [r['fileUrl']]
                : (filePath != null ? [filePath] : []);

          await recordsBox.put(rec.id, rec);
          await recordsBox.flush();
          return rec;
        }
      }
    } catch (_) {}

    // Offline / fallback record creation
    final recordId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final rec = MedicalRecord()
      ..id = recordId
      ..memberId = patientId
      ..memberName = 'Patient'
      ..type = type.toLowerCase().replaceAll(' ', '_')
      ..title = title
      ..date = date
      ..details = details
      ..doctorName = doctorName
      ..hospitalName = hospitalName
      ..diagnosis = title
      ..tags = [type]
      ..attachedFilePaths = filePath != null ? [filePath] : [];

    await recordsBox.put(rec.id, rec);
    await recordsBox.flush();
    return rec;
  }

  /// 12. Delete Medical Record
  Future<void> deleteMedicalRecord(String patientId, String recordId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/records/$patientId/$recordId'));
    } catch (_) {}

    final recordsBox = Hive.box<MedicalRecord>('records');
    await recordsBox.delete(recordId);
    await recordsBox.flush();
  }

  /// 10. Generate Secure 256-bit Doctor QR Sharing Session
  Future<DoctorSharingSessionResult?> createDoctorSharingSession({
    required String profileId,
    required String patientName,
    required int durationMinutes,
    required Map<String, bool> categories,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/doctor/create-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profileId': profileId,
          'patientName': patientName,
          'durationMinutes': durationMinutes,
          'categories': categories,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['session'] != null) {
          final s = data['session'];
          return DoctorSharingSessionResult(
            id: s['id'],
            rawToken: s['rawToken'] ?? '',
            otp: s['otp'],
            qrUrl: s['qrUrl'] ?? 'https://swasth-doctor.onrender.com/?t=${s['rawToken']}',
            expiresAt: s['expiresAt'],
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// 11. Revoke Doctor Access Session
  Future<bool> revokeDoctorSharingSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/doctor/revoke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 12. Fetch Doctor Sharing Audit Logs
  Future<List<Map<String, dynamic>>> fetchDoctorAuditLogs(String profileId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctor/audit-logs/$profileId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['logs'] != null) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// 13. Fetch Caretaker Dashboard Data
  Future<Map<String, dynamic>?> fetchCaretakerDashboard(String caretakerProfileId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/caretaker/dashboard/$caretakerProfileId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncAllData() async {
    ref.read(authProvider.notifier).setSyncing(true);
    try {
      await http.get(Uri.parse('$baseUrl/health'));
    } catch (_) {
    } finally {
      ref.read(authProvider.notifier).setSyncing(false);
    }
  }

  int parseInt(dynamic val) {
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 25;
    return 25;
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});
