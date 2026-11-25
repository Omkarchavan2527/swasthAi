import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';
import '../../widgets/sw_button.dart';
import '../medicines/prescription_scan_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting(String lang) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppTranslations.tr(lang, 'greetingMorning');
    if (hour < 17) return AppTranslations.tr(lang, 'greetingAfternoon');
    return AppTranslations.tr(lang, 'greetingEvening');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMember = ref.watch(activeMemberProvider);
    final medicines = ref.watch(activeMemberMedicinesProvider);
    final doses = ref.watch(activeScheduledDosesProvider);
    final isFamilyMode = ref.watch(authProvider).isFamilyMemberMode;
    final lang = ref.watch(languageProvider);

    final completedDosesCount = doses.where((d) => d.isTaken).length;
    final totalDosesCount = doses.isNotEmpty ? doses.length : medicines.length;
    final adherenceRate = totalDosesCount > 0 ? (completedDosesCount / totalDosesCount * 100).round() : 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Clinical Calm Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeMember != null
                                  ? '${_getGreeting(lang)}, ${activeMember.name.split(' ')[0]} 👋'
                                  : '${_getGreeting(lang)}! 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121C2A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFamilyMode
                                  ? AppTranslations.tr(lang, 'familyMode')
                                  : AppTranslations.tr(lang, 'healthSummary'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => context.push('/dashboard/notifications'),
                          icon: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.notifications_none, color: Color(0xFF00685F), size: 20),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFBA1A1A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Security Badge & Family Mode indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user, size: 14, color: Color(0xFF006F67)),
                              const SizedBox(width: 6),
                              Text(
                                AppTranslations.tr(lang, 'securityVault'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006F67),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isFamilyMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: const Color(0xFF00685F).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.family_restroom, size: 14, color: Color(0xFF00685F)),
                                const SizedBox(width: 6),
                                Text(
                                  AppTranslations.tr(lang, 'familyMode'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00685F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Family Profiles Switcher Strip
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: MemberSwitcher(),
              ),
            ),

            if (activeMember != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Daily Vitals Streak Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.health_and_safety, color: Color(0xFF00685F), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.tr(lang, 'adherence'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121C2A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$adherenceRate% on track',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121C2A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Quick Vitals 2x2 Bento Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.tr(lang, 'vitalsTitle'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                        ),
                        InkWell(
                          onTap: () => context.push('/dashboard/trends'),
                          child: Row(
                            children: [
                              Text(AppTranslations.tr(lang, 'actionTrends'), style: const TextStyle(color: Color(0xFF00685F), fontSize: 13, fontWeight: FontWeight.w600)),
                              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF00685F)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _VitalsBentoTile(
                          icon: Icons.favorite,
                          label: AppTranslations.tr(lang, 'bp'),
                          value: '118/76',
                          unit: 'mmHg',
                          statusBadge: 'Normal',
                          timestamp: 'Today',
                          accentColor: const Color(0xFF00685F),
                        ),
                        _VitalsBentoTile(
                          icon: Icons.water_drop,
                          label: AppTranslations.tr(lang, 'sugar'),
                          value: '94',
                          unit: 'mg/dL',
                          statusBadge: 'Fasting',
                          timestamp: 'Today',
                          accentColor: const Color(0xFF0284C7),
                        ),
                        _VitalsBentoTile(
                          icon: Icons.monitor_heart,
                          label: AppTranslations.tr(lang, 'heartRate'),
                          value: '72',
                          unit: 'bpm',
                          statusBadge: 'Resting',
                          timestamp: 'Today',
                          accentColor: const Color(0xFFE11D48),
                        ),
                        _VitalsBentoTile(
                          icon: Icons.fitness_center,
                          label: AppTranslations.tr(lang, 'weight'),
                          value: '68',
                          unit: 'kg',
                          statusBadge: 'Stable',
                          timestamp: 'Today',
                          accentColor: const Color(0xFF059669),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. Today's Medicines Bento Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppTranslations.tr(lang, 'todaysMedicines'),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                doses.isNotEmpty
                                    ? '$completedDosesCount/$totalDosesCount ${AppTranslations.tr(lang, 'taken')}'
                                    : '${medicines.length} ${AppTranslations.tr(lang, 'navMedicines')}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/dashboard/medicines'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: Text(AppTranslations.tr(lang, 'medicinesSubtitle'), style: const TextStyle(color: Color(0xFF00685F), fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (doses.isEmpty && medicines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF00685F)),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.tr(lang, 'noMedicines'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.tr(lang, 'allTaken'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (doses.isNotEmpty)
                      ...doses.map((dose) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dose.isTaken ? const Color(0xFFCCFBF1) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: dose.isTaken ? const Color(0xFFCCFBF1) : const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                dose.isTaken ? Icons.check : Icons.medication,
                                color: dose.isTaken ? const Color(0xFF006F67) : const Color(0xFF00685F),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dose.medicineName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFF121C2A),
                                      decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    '${dose.dosage} • ${dose.scheduledTime}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: dose.isTaken,
                              activeColor: const Color(0xFF00685F),
                              onChanged: (v) {
                                ref.read(activeScheduledDosesProvider.notifier).toggleDose(dose.id);
                              },
                            ),
                          ],
                        ),
                      ))
                    else
                      ...medicines.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medication, color: Color(0xFF00685F), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121C2A))),
                                  Text('${m.dosage} • ${m.timing}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: m.takenToday,
                              activeColor: const Color(0xFF00685F),
                              onChanged: (v) {},
                            ),
                          ],
                        ),
                      )),

                    const SizedBox(height: 20),

                    // 4. Quick Actions Bento Row
                    Text(
                      AppTranslations.tr(lang, 'quickActions'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => PrescriptionScanDialog.show(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF99F6E4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.camera_alt, color: Color(0xFF00685F), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.tr(lang, 'actionScanPrescription'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006F67)),
                                        ),
                                        Text('AI Camera schedule', style: const TextStyle(fontSize: 10, color: Color(0xFF0F766E))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go('/dashboard/doctor-access'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code, color: Color(0xFF00685F), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.tr(lang, 'actionDoctorQr'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                                        ),
                                        const Text('Share OTP access', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/dashboard/emergency'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFB4AB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emergency, color: Color(0xFFBA1A1A), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.tr(lang, 'emergencyTitle'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF93000A)),
                                        ),
                                        const Text('108 / ICE contact', style: TextStyle(fontSize: 10, color: Color(0xFF93000A))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/dashboard/vaccinations'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.vaccines, color: Color(0xFF00685F), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.tr(lang, 'vaccinesTitle'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                                        ),
                                        const Text('Immunization log', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              )
            else
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.tr(lang, 'noFamilyMembers'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTranslations.tr(lang, 'familySubtitle'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SWButton(
                        text: '+ ${AppTranslations.tr(lang, 'addFamilyMember')}',
                        onPressed: () => context.go('/dashboard/family'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VitalsBentoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String statusBadge;
  final String timestamp;
  final Color accentColor;

  const _VitalsBentoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.statusBadge,
    required this.timestamp,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x040F172A), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  statusBadge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Text(timestamp, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
