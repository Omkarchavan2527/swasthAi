import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/family_member.dart';
import '../data/models/medical_record.dart';
import '../data/models/health_measurement.dart';
import '../providers/family_provider.dart';
import '../providers/medicine_provider.dart';

/// Builds a structured RAG context string from the active family member's
/// real medical data — records, medicines, vitals, and family profile.
/// This context is injected into the AI system prompt so the assistant
/// can answer questions grounded in the patient's actual health history.
class RagContextBuilder {
  /// Maximum characters for the RAG context block to stay within token budget
  static const int _maxContextChars = 6000;

  /// Build the full RAG context for the currently active family member.
  static String buildContext(dynamic ref) {
    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return '';

    final buffer = StringBuffer();

    // 1. Patient Profile
    buffer.writeln(_buildPatientProfile(activeMember));

    // 2. Family Overview (brief)
    buffer.writeln(_buildFamilyOverview(ref, activeMember.id));

    // 3. Current Medicines
    buffer.writeln(_buildMedicinesContext(ref, activeMember.id));

    // 4. Today's Dose Adherence
    buffer.writeln(_buildDoseAdherence(ref));

    // 5. Recent Health Measurements (vitals)
    buffer.writeln(_buildVitalsContext(activeMember.id));

    // 6. Medical Records (prescriptions, lab reports, doctor visits)
    buffer.writeln(_buildRecordsContext(activeMember.id));

    // Truncate if exceeds budget
    String context = buffer.toString();
    if (context.length > _maxContextChars) {
      context = '${context.substring(0, _maxContextChars)}\n[...additional records truncated for brevity]';
    }

    return context;
  }

  /// Build patient profile section
  static String _buildPatientProfile(FamilyMember member) {
    return '''
═══ PATIENT PROFILE ═══
Name: ${member.name}
Age: ${member.age} years
Gender: ${member.gender}
Relationship: ${member.relationship}
Blood Group: ${member.bloodGroup}
Chronic Conditions: ${member.chronicConditions.isEmpty ? 'None reported' : member.chronicConditions.join(', ')}
Phone: ${member.phone.isNotEmpty ? member.phone : 'Not provided'}''';
  }

  /// Build brief family overview for context
  static String _buildFamilyOverview(dynamic ref, String activeMemberId) {
    final allMembers = ref.read(familyMembersProvider);
    if (allMembers.length <= 1) return '';

    final buffer = StringBuffer();
    buffer.writeln('\n═══ FAMILY MEMBERS ═══');
    for (final m in allMembers) {
      if (m.id == activeMemberId) continue;
      final conditions = m.chronicConditions.isNotEmpty
          ? ' [${m.chronicConditions.join(", ")}]'
          : '';
      buffer.writeln(
          '• ${m.name} (${m.relationship}, ${m.age}y, ${m.gender}, ${m.bloodGroup})$conditions');
    }
    return buffer.toString();
  }

  /// Build current medicines section with dosage, timing, instructions
  static String _buildMedicinesContext(dynamic ref, String memberId) {
    final medicines = ref.read(activeMemberMedicinesProvider);
    if (medicines.isEmpty) return '\n═══ CURRENT MEDICINES ═══\nNo active medicines prescribed.';

    final buffer = StringBuffer();
    buffer.writeln('\n═══ CURRENT MEDICINES ═══');
    for (int i = 0; i < medicines.length; i++) {
      final m = medicines[i];
      buffer.writeln('${i + 1}. ${m.name}');
      buffer.writeln('   Dosage: ${m.dosage}');
      buffer.writeln('   Frequency: ${m.frequency}');
      buffer.writeln('   Scheduled Times: ${m.scheduledTimes.join(", ")}');
      if (m.instructions.isNotEmpty) {
        buffer.writeln('   Instructions: ${m.instructions}');
      }
      if (m.prescribedBy != null && m.prescribedBy!.isNotEmpty) {
        buffer.writeln('   Prescribed By: ${m.prescribedBy}');
      }
      if (m.startDate.isNotEmpty) {
        buffer.writeln('   Start Date: ${m.startDate}');
      }
      if (m.endDate.isNotEmpty) {
        buffer.writeln('   End Date: ${m.endDate}');
      }
    }
    return buffer.toString();
  }

  /// Build today's dose adherence status
  static String _buildDoseAdherence(dynamic ref) {
    final doses = ref.read(activeScheduledDosesProvider);
    if (doses.isEmpty) return '';

    final taken = doses.where((d) => d.isTaken).length;
    final total = doses.length;
    final pending = doses.where((d) => !d.isTaken).toList();

    final buffer = StringBuffer();
    buffer.writeln('\n═══ TODAY\'S DOSE ADHERENCE ═══');
    buffer.writeln('Status: $taken/$total doses taken (${total > 0 ? (taken * 100 ~/ total) : 0}%)');

    if (pending.isNotEmpty) {
      buffer.writeln('Pending Doses:');
      for (final d in pending) {
        buffer.writeln('  • ${d.medicineName} ${d.dosage} at ${d.scheduledTime}');
      }
    }

    // Weekly adherence streak
    final settingsBox = Hive.box('settings');
    final memberId = doses.isNotEmpty ? doses.first.profileId : '';
    if (memberId.isNotEmpty) {
      final streakDates = List<String>.from(
          settingsBox.get('streak_dates_$memberId', defaultValue: []));
      if (streakDates.isNotEmpty) {
        buffer.writeln('Adherence Streak: ${streakDates.length} day(s) of 100% completion');
      }
    }
    return buffer.toString();
  }

  /// Build recent vital signs / health measurements
  static String _buildVitalsContext(String memberId) {
    final box = Hive.box<HealthMeasurement>('measurements');
    final memberMeasurements = box.values
        .where((m) => m.memberId == memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (memberMeasurements.isEmpty) {
      return '\n═══ RECENT VITALS ═══\nNo health measurements recorded.';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n═══ RECENT VITALS (last 5 readings) ═══');

    final recent = memberMeasurements.take(5);
    for (final m in recent) {
      buffer.writeln('Date: ${m.date}');
      buffer.writeln('  BP: ${m.systolicBP}/${m.diastolicBP} mmHg'
          '${_bpCategory(m.systolicBP, m.diastolicBP)}');
      buffer.writeln('  Blood Sugar: ${m.bloodSugar} mg/dL'
          '${_sugarCategory(m.bloodSugar)}');
      buffer.writeln('  Weight: ${m.weight} kg');
      buffer.writeln('  Heart Rate: ${m.heartRate} bpm'
          '${_hrCategory(m.heartRate)}');
    }

    // Trend analysis
    if (memberMeasurements.length >= 2) {
      final latest = memberMeasurements.first;
      final previous = memberMeasurements[1];
      buffer.writeln('\nTrend (latest vs previous):');
      final bpDiff = latest.systolicBP - previous.systolicBP;
      final sugarDiff = latest.bloodSugar - previous.bloodSugar;
      final weightDiff = latest.weight - previous.weight;
      buffer.writeln('  BP: ${bpDiff >= 0 ? "+$bpDiff" : "$bpDiff"} mmHg systolic');
      buffer.writeln('  Sugar: ${sugarDiff >= 0 ? "+${sugarDiff.toStringAsFixed(1)}" : sugarDiff.toStringAsFixed(1)} mg/dL');
      buffer.writeln('  Weight: ${weightDiff >= 0 ? "+${weightDiff.toStringAsFixed(1)}" : weightDiff.toStringAsFixed(1)} kg');
    }

    return buffer.toString();
  }

  /// Build medical records summary (prescriptions, lab reports, visits)
  static String _buildRecordsContext(String memberId) {
    final box = Hive.box<MedicalRecord>('records');
    final memberRecords = box.values
        .where((r) => r.memberId == memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (memberRecords.isEmpty) {
      return '\n═══ MEDICAL RECORDS ═══\nNo medical records on file.';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n═══ MEDICAL RECORDS (${memberRecords.length} total, showing recent) ═══');

    // Group by type for structured overview
    final byType = <String, List<MedicalRecord>>{};
    for (final r in memberRecords) {
      byType.putIfAbsent(r.type, () => []).add(r);
    }

    // Show summary counts by type
    buffer.writeln('Record Types: ${byType.entries.map((e) => "${_recordTypeLabel(e.key)}: ${e.value.length}").join(", ")}');
    buffer.writeln('');

    // Show details of the most recent records (limit to 8 to control context size)
    final recentRecords = memberRecords.take(8);
    for (final r in recentRecords) {
      buffer.writeln('📋 ${_recordTypeLabel(r.type)} — ${r.title}');
      buffer.writeln('   Date: ${r.date}');
      if (r.doctorName != null && r.doctorName!.isNotEmpty) {
        buffer.writeln('   Doctor: ${r.doctorName}');
      }
      if (r.hospitalName != null && r.hospitalName!.isNotEmpty) {
        buffer.writeln('   Hospital: ${r.hospitalName}');
      }
      if (r.diagnosis != null && r.diagnosis!.isNotEmpty) {
        buffer.writeln('   Diagnosis: ${r.diagnosis}');
      }
      if (r.details.isNotEmpty) {
        // Limit details to avoid bloating context
        final details = r.details.length > 200
            ? '${r.details.substring(0, 200)}...'
            : r.details;
        buffer.writeln('   Details: $details');
      }
      if (r.tags.isNotEmpty) {
        buffer.writeln('   Tags: ${r.tags.join(", ")}');
      }
      if (r.attachedFilePaths.isNotEmpty) {
        buffer.writeln('   Attachments: ${r.attachedFilePaths.length} file(s)');
      }
      buffer.writeln('');
    }

    if (memberRecords.length > 8) {
      buffer.writeln('[...${memberRecords.length - 8} older records not shown]');
    }

    return buffer.toString();
  }

  // ── Helper: BP category annotation ──
  static String _bpCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return ' (Normal)';
    if (systolic < 130 && diastolic < 80) return ' (Elevated)';
    if (systolic < 140 || diastolic < 90) return ' (Stage 1 Hypertension)';
    if (systolic >= 140 || diastolic >= 90) return ' (Stage 2 Hypertension)';
    if (systolic > 180 || diastolic > 120) return ' (⚠️ HYPERTENSIVE CRISIS)';
    return '';
  }

  // ── Helper: Blood sugar category ──
  static String _sugarCategory(double sugar) {
    if (sugar < 70) return ' (⚠️ Low / Hypoglycemia)';
    if (sugar <= 110) return ' (Normal Fasting)';
    if (sugar <= 140) return ' (Pre-diabetic range)';
    return ' (⚠️ Diabetic range)';
  }

  // ── Helper: Heart rate category ──
  static String _hrCategory(int hr) {
    if (hr < 60) return ' (Bradycardia)';
    if (hr <= 100) return ' (Normal)';
    return ' (Tachycardia)';
  }

  // ── Helper: Readable record type label ──
  static String _recordTypeLabel(String type) {
    switch (type) {
      case 'doctor_visit':
        return 'Doctor Visit';
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'xray':
        return 'X-Ray';
      case 'mri':
        return 'MRI Scan';
      case 'photo':
        return 'Photo';
      case 'vaccination':
        return 'Vaccination';
      case 'discharge':
        return 'Discharge Summary';
      case 'history':
        return 'Medical History';
      case 'measurement':
        return 'Measurement';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  /// Search / filter records relevant to a user query using keyword matching.
  /// Returns a focused subset of records that match the query topic.
  static String searchRelevantRecords(dynamic ref, String query) {
    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return '';

    final lower = query.toLowerCase();
    final box = Hive.box<MedicalRecord>('records');
    final memberRecords = box.values
        .where((r) => r.memberId == activeMember.id)
        .toList();

    if (memberRecords.isEmpty) return '';

    // Score each record by keyword relevance to the query
    final scored = <MapEntry<MedicalRecord, int>>[];
    for (final r in memberRecords) {
      int score = 0;
      final searchableText = '${r.title} ${r.details} ${r.diagnosis ?? ''} '
              '${r.doctorName ?? ''} ${r.hospitalName ?? ''} ${r.tags.join(' ')} ${r.type}'
          .toLowerCase();

      // Extract keywords from user query (split by space, filter small words)
      final keywords = lower
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();

      for (final kw in keywords) {
        if (searchableText.contains(kw)) score += 2;
      }

      // Boost by record type relevance
      if (lower.contains('medicine') || lower.contains('prescription') || lower.contains('दवा') || lower.contains('औषध')) {
        if (r.type == 'prescription') score += 3;
      }
      if (lower.contains('lab') || lower.contains('test') || lower.contains('report') || lower.contains('तपासणी') || lower.contains('जांच')) {
        if (r.type == 'lab_report') score += 3;
      }
      if (lower.contains('doctor') || lower.contains('visit') || lower.contains('डॉक्टर') || lower.contains('भेट')) {
        if (r.type == 'doctor_visit') score += 3;
      }
      if (lower.contains('bp') || lower.contains('pressure') || lower.contains('sugar') || lower.contains('diabetes')) {
        if (r.type == 'measurement' || r.type == 'lab_report') score += 3;
      }
      if (lower.contains('xray') || lower.contains('x-ray') || lower.contains('mri') || lower.contains('scan')) {
        if (r.type == 'xray' || r.type == 'mri') score += 3;
      }

      if (score > 0) {
        scored.add(MapEntry(r, score));
      }
    }

    if (scored.isEmpty) return '';

    // Sort by relevance score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('\n═══ QUERY-RELEVANT RECORDS ═══');
    for (final entry in scored.take(5)) {
      final r = entry.key;
      buffer.writeln('• ${_recordTypeLabel(r.type)}: ${r.title} (${r.date})');
      if (r.diagnosis != null && r.diagnosis!.isNotEmpty) {
        buffer.writeln('  Diagnosis: ${r.diagnosis}');
      }
      if (r.details.isNotEmpty) {
        final details = r.details.length > 150
            ? '${r.details.substring(0, 150)}...'
            : r.details;
        buffer.writeln('  Details: $details');
      }
    }
    return buffer.toString();
  }
}
