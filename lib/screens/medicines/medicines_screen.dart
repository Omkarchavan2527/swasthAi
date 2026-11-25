import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/scheduled_dose.dart';
import '../../providers/family_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/member_switcher.dart';
import 'prescription_scan_dialog.dart';

class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key});

  void _showAddMedicineDialog(BuildContext context, WidgetRef ref, [String lang = 'en']) {
    final activeMember = ref.read(activeMemberProvider);
    final allMembers = ref.read(familyMembersProvider);
    final eligibleCaretakers = allMembers.where((m) => m.id != activeMember?.id).toList();

    final nameController = TextEditingController();
    final dosageController = TextEditingController(text: '1 tablet');
    final instructionsController = TextEditingController();
    final time1Controller = TextEditingController(text: '08:00');
    final time2Controller = TextEditingController(text: '13:00');
    final time3Controller = TextEditingController(text: '20:00');

    bool addMultipleDoses = false;
    int reminderBefore = 15;
    int gracePeriod = 15;
    String frequency = 'Daily';
    String? selectedCaretakerId = activeMember?.caretakerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication, color: Color(0xFF00685F), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.tr(lang, 'addMedicineRoutine'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF121C2A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scan Prescription with AI Camera Banner
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    PrescriptionScanDialog.show(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF00685F), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '📸 Auto-schedule with AI using Prescription Camera',
                            style: TextStyle(
                              color: Color(0xFF006F67),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF00685F)),
                      ],
                    ),
                  ),
                ),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '${AppTranslations.tr(lang, 'medName')} *',
                    hintText: 'e.g. Metformin, Amlodipine',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    prefixIcon: const Icon(Icons.medication, size: 18, color: Color(0xFF00685F)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: '${AppTranslations.tr(lang, 'dosage')} *',
                    hintText: 'e.g. 500mg, 1 tablet',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: time1Controller,
                        decoration: InputDecoration(
                          labelText: 'Scheduled Time 1 (HH:MM)',
                          hintText: '08:00',
                          filled: true,
                          fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        addMultipleDoses ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        color: const Color(0xFF00685F),
                      ),
                      onPressed: () {
                        setState(() => addMultipleDoses = !addMultipleDoses);
                      },
                    ),
                  ],
                ),
                if (addMultipleDoses) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: time2Controller,
                    decoration: InputDecoration(
                      labelText: 'Scheduled Time 2 (HH:MM)',
                      hintText: '13:00',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: time3Controller,
                    decoration: InputDecoration(
                      labelText: 'Scheduled Time 3 (HH:MM)',
                      hintText: '20:00',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: reminderBefore,
                  decoration: InputDecoration(
                    labelText: 'Advance Patient Reminder',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    prefixIcon: const Icon(Icons.alarm, color: Color(0xFF00685F), size: 18),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('At Scheduled Time')),
                    DropdownMenuItem(value: 5, child: Text('5 mins before')),
                    DropdownMenuItem(value: 10, child: Text('10 mins before')),
                    DropdownMenuItem(value: 15, child: Text('15 mins before (Recommended)')),
                    DropdownMenuItem(value: 30, child: Text('30 mins before')),
                  ],
                  onChanged: (v) => setState(() => reminderBefore = v ?? 15),
                ),
                const SizedBox(height: 12),

                // Caretaker Selection Dropdown
                DropdownButtonFormField<String?>(
                  value: selectedCaretakerId,
                  decoration: InputDecoration(
                    labelText: 'Assign Caretaker (Escalation)',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    prefixIcon: const Icon(Icons.person_pin_circle, color: Color(0xFF00685F), size: 18),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (No Caretaker)'),
                    ),
                    ...eligibleCaretakers.map((m) => DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text('${m.name} (${m.relationship})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => selectedCaretakerId = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: gracePeriod,
                  decoration: InputDecoration(
                    labelText: 'Caretaker Grace Period',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    prefixIcon: const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 mins grace period')),
                    DropdownMenuItem(value: 10, child: Text('10 mins grace period')),
                    DropdownMenuItem(value: 15, child: Text('15 mins grace period')),
                    DropdownMenuItem(value: 30, child: Text('30 mins grace period')),
                    DropdownMenuItem(value: 60, child: Text('60 mins grace period')),
                  ],
                  onChanged: (v) => setState(() => gracePeriod = v ?? 15),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: instructionsController,
                  decoration: InputDecoration(
                    labelText: 'Instructions / Food Timing',
                    hintText: 'e.g. After breakfast with warm water',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final dosage = dosageController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter medicine name.')),
                        );
                        return;
                      }

                      final List<String> times = [time1Controller.text.trim()];
                      if (addMultipleDoses) {
                        if (time2Controller.text.isNotEmpty) times.add(time2Controller.text.trim());
                        if (time3Controller.text.isNotEmpty) times.add(time3Controller.text.trim());
                      }

                      // 1. Add Medicine Schedule
                      await ref.read(medicinesProvider.notifier).addMedicine(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            scheduledTimes: times,
                            reminderBeforeMinutes: reminderBefore,
                            gracePeriodMinutes: gracePeriod,
                            instructions: instructionsController.text,
                          );

                      // 2. Assign Caretaker if selected
                      if (activeMember != null && selectedCaretakerId != null) {
                        await ref
                            .read(familyMembersProvider.notifier)
                            .assignCaretaker(activeMember.id, selectedCaretakerId);
                      }

                      // 3. Schedule Local Advance Reminder Notification
                      await NotificationService().showMedicineReminder(
                        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        medicineName: name,
                        scheduledTime: times.first,
                        dosage: dosage,
                        minutesBefore: reminderBefore,
                      );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selectedCaretakerId != null
                                  ? 'Added $name! Caretaker assigned for missed dose alerts.'
                                  : 'Added $name to schedule with $reminderBefore-min advance reminders!',
                            ),
                            backgroundColor: const Color(0xFF00685F),
                          ),
                        );
                      }
                    },
                    child: Text(AppTranslations.tr(lang, 'saveMedicineSchedule'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMember = ref.watch(activeMemberProvider);
    final medicines = ref.watch(activeMemberMedicinesProvider);
    final doses = ref.watch(activeScheduledDosesProvider);
    final lang = ref.watch(languageProvider);

    // Dynamic Adherence Metrics Calculation
    final totalDosesCount = doses.length;
    final takenDosesCount = doses.where((d) => d.isTaken).length;
    final adherenceFraction = totalDosesCount > 0 ? (takenDosesCount / totalDosesCount) : 0.0;
    final adherencePercent = (adherenceFraction * 100).round();

    // Calculate Dynamic 7 Days of the Current Week (Monday through Sunday)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLetters = [
      AppTranslations.tr(lang, 'dayMon'),
      AppTranslations.tr(lang, 'dayTue'),
      AppTranslations.tr(lang, 'dayWed'),
      AppTranslations.tr(lang, 'dayThu'),
      AppTranslations.tr(lang, 'dayFri'),
      AppTranslations.tr(lang, 'daySat'),
      AppTranslations.tr(lang, 'daySun'),
    ];

    // Read saved streak dates from Hive
    final settingsBox = Hive.box('settings');
    final profileId = activeMember?.id ?? 'default';
    final streakDates = List<String>.from(settingsBox.get('streak_dates_$profileId', defaultValue: []));
    final todayStr = now.toIso8601String().substring(0, 10);
    final todayCompleted = totalDosesCount > 0 && takenDosesCount == totalDosesCount;

    // Calculate consecutive days streak
    int currentStreak = 0;
    var checkDay = DateTime(now.year, now.month, now.day);
    if (todayCompleted || streakDates.contains(todayStr)) {
      currentStreak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    } else {
      checkDay = checkDay.subtract(const Duration(days: 1));
    }
    while (streakDates.contains(checkDay.toIso8601String().substring(0, 10))) {
      currentStreak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppTranslations.tr(lang, 'medicinesTitle')} (${activeMember?.name ?? ""})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: AppTranslations.tr(lang, 'scanWithCamera'),
            onPressed: () => PrescriptionScanDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppTranslations.tr(lang, 'syncMedicines'),
            onPressed: () async {
              await ref.read(medicinesProvider.notifier).loadMedicines();
              await ref.read(activeScheduledDosesProvider.notifier).loadDoses();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppTranslations.tr(lang, 'syncMedicines'))),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const MemberSwitcher(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(medicinesProvider.notifier).loadMedicines();
                await ref.read(activeScheduledDosesProvider.notifier).loadDoses();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  // 1. Dynamic Bento Adherence & Streak Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Progress Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: CircularProgressIndicator(
                                    value: totalDosesCount > 0 ? adherenceFraction : 0.0,
                                    backgroundColor: const Color(0xFFE6EEFF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00685F)),
                                    strokeWidth: 5.5,
                                  ),
                                ),
                                Text(
                                  totalDosesCount > 0 ? '$adherencePercent%' : '0%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF00685F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.tr(lang, 'adherence'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    totalDosesCount > 0
                                        ? '$takenDosesCount of $totalDosesCount ${AppTranslations.tr(lang, 'taken')}'
                                        : (medicines.isNotEmpty
                                            ? '0 of ${medicines.length} ${AppTranslations.tr(lang, 'taken')}'
                                            : AppTranslations.tr(lang, 'noMedicines')),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department, color: Color(0xFF006F67), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentStreak > 0
                                        ? '$currentStreak ${AppTranslations.tr(lang, 'daysStreak')}'
                                        : (todayCompleted ? '1 ${AppTranslations.tr(lang, 'daysStreak')}' : 'Streak: $currentStreak'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF006F67)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Dynamic Weekly Calendar Strip (Monday -> Sunday)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final dayDate = weekDays[i];
                            final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
                            final dateStr = dayDate.toIso8601String().substring(0, 10);
                            final isDone = isToday
                                ? todayCompleted
                                : (streakDates.contains(dateStr) || (dayDate.isBefore(now) && streakDates.isNotEmpty && i < now.weekday - 1));

                            return _DayPill(
                              day: dayLetters[i],
                              date: '${dayDate.day}',
                              isDone: isDone,
                              isToday: isToday,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Refill Alert Banner (Low stock reminder)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFB4AB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notification_important, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppTranslations.tr(lang, 'refillReminder'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF93000A)),
                                  ),
                                  Text(
                                    AppTranslations.tr(lang, 'statusDue'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF93000A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppTranslations.tr(lang, 'medicinesSubtitle'),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF93000A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Today's Dosing Routines Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.tr(lang, 'medicationSchedule'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121C2A),
                        ),
                      ),
                      Text(
                        '${doses.where((d) => d.isTaken).length}/${doses.isNotEmpty ? doses.length : medicines.length} ${AppTranslations.tr(lang, 'taken')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00685F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (medicines.isEmpty && doses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.medication_outlined, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.tr(lang, 'noMedicines'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppTranslations.tr(lang, 'medicinesSubtitle'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00685F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(AppTranslations.tr(lang, 'scanPrescription')),
                            onPressed: () => PrescriptionScanDialog.show(context),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Morning Routine Group
                    _buildRoutineSection(
                      context,
                      ref,
                      title: '${AppTranslations.tr(lang, 'morning')} ${AppTranslations.tr(lang, 'timing')}',
                      timeRange: '8:00 AM – 10:00 AM',
                      icon: Icons.wb_sunny,
                      doses: doses.where((d) => d.scheduledTime.compareTo('12:00') < 0).toList(),
                      lang: lang,
                    ),
                    const SizedBox(height: 14),

                    // Afternoon Routine Group
                    _buildRoutineSection(
                      context,
                      ref,
                      title: '${AppTranslations.tr(lang, 'afternoon')} ${AppTranslations.tr(lang, 'timing')}',
                      timeRange: '1:00 PM – 2:30 PM',
                      icon: Icons.light_mode,
                      doses: doses
                          .where((d) =>
                              d.scheduledTime.compareTo('12:00') >= 0 &&
                              d.scheduledTime.compareTo('17:00') < 0)
                          .toList(),
                      lang: lang,
                    ),
                    const SizedBox(height: 14),

                    // Night Routine Group
                    _buildRoutineSection(
                      context,
                      ref,
                      title: '${AppTranslations.tr(lang, 'night')} ${AppTranslations.tr(lang, 'timing')}',
                      timeRange: '8:00 PM – 10:00 PM',
                      icon: Icons.nightlight_round,
                      doses: doses.where((d) => d.scheduledTime.compareTo('17:00') >= 0).toList(),
                      lang: lang,
                    ),

                    const SizedBox(height: 24),

                    // Configured Prescriptions List
                    if (medicines.isNotEmpty) ...[
                      const Text(
                        "PRESCRIBED MEDICINES IN VAULT",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...medicines.map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: m.prescribedBy != null ? const Color(0xFFEEF2FF) : const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        m.prescribedBy != null ? Icons.medical_services : Icons.medication,
                                        color: m.prescribedBy != null ? const Color(0xFF4F46E5) : const Color(0xFF00685F),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  m.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                                                ),
                                              ),
                                              if (m.prescribedBy != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEEF2FF),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text('Doctor Rx', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('${m.dosage} • Slot: ${m.scheduledTimes.join(", ")}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 20),
                                      onPressed: () {
                                        ref.read(medicinesProvider.notifier).deleteMedicine(m.id);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${m.name}')));
                                      },
                                    ),
                                  ],
                                ),
                                if (m.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 44),
                                    child: Text(
                                      m.instructions,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scanRxFab',
            backgroundColor: const Color(0xFF00685F),
            onPressed: () => PrescriptionScanDialog.show(context),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            label: Text(
              '📸 ${AppTranslations.tr(lang, 'scanPrescription')}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'addManualFab',
            backgroundColor: Colors.white,
            onPressed: () => _showAddMedicineDialog(context, ref, lang),
            icon: const Icon(Icons.add, color: Color(0xFF00685F), size: 20),
            label: Text(
              '+ ${AppTranslations.tr(lang, 'scheduleMedicine')}',
              style: const TextStyle(color: Color(0xFF00685F), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String timeRange,
    required IconData icon,
    required List<ScheduledDose> doses,
    required String lang,
  }) {
    if (doses.isEmpty) return const SizedBox.shrink();

    final takenCount = doses.where((d) => d.isTaken).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF006F67), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                ),
                const SizedBox(width: 6),
                Text(
                  timeRange,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: takenCount == doses.length ? const Color(0xFFDCFCE7) : const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '$takenCount of ${doses.length} ${AppTranslations.tr(lang, 'taken')}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: takenCount == doses.length ? const Color(0xFF15803D) : const Color(0xFF00685F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...doses.map((dose) => _buildDoseCard(context, ref, dose, lang)),
      ],
    );
  }

  Widget _buildDoseCard(BuildContext context, WidgetRef ref, ScheduledDose dose, String lang) {
    final isTaken = dose.isTaken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x040F172A), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFFDCFCE7) : const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTaken ? Icons.check_circle : Icons.medication,
              color: isTaken ? const Color(0xFF16A34A) : const Color(0xFF00685F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        dose.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121C2A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTaken)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${AppTranslations.tr(lang, 'taken')} ✓', style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (dose.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(AppTranslations.tr(lang, 'statusDue'), style: const TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${dose.dosage} • Scheduled: ${dose.scheduledTime}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (dose.instructions != null && dose.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    dose.instructions!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isTaken)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00685F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ref.read(activeScheduledDosesProvider.notifier).markDoseTaken(dose.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ ${AppTranslations.tr(lang, 'taken')}: ${dose.medicineName}'),
                    backgroundColor: const Color(0xFF00685F),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(AppTranslations.tr(lang, 'markTaken'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBBF7D0)),
                foregroundColor: const Color(0xFF15803D),
                backgroundColor: const Color(0xFFF0FDF4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
              label: Text(AppTranslations.tr(lang, 'undoTaken'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(activeScheduledDosesProvider.notifier).unmarkDoseTaken(dose.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppTranslations.tr(lang, 'undoTaken')}: ${dose.medicineName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String day;
  final String date;
  final bool isDone;
  final bool isToday;

  const _DayPill({
    required this.day,
    required this.date,
    required this.isDone,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (isToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00685F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x1A00685F), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
            Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Today', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(day, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF121C2A))),
          const SizedBox(height: 4),
          if (isDone)
            const Icon(Icons.check_circle, size: 14, color: Color(0xFF00685F))
          else
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
