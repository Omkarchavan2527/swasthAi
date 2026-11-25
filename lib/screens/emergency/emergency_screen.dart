import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _shareLocation(BuildContext context, String patientName) {
    Share.share(
      'EMERGENCY SOS: $patientName requires urgent medical assistance! Current location broadcast initiated. Contact: 108 / Family Guardians.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMember = ref.watch(activeMemberProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Color(0xFFBA1A1A)),
            const SizedBox(width: 8),
            Text(
              AppTranslations.tr(lang, 'emergencyTitle'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Color(0xFFBA1A1A)),
            tooltip: AppTranslations.tr(lang, 'callAmbulance'),
            onPressed: () => _makeCall('108'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Live Emergency Dispatch Radar Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x33BA1A1A), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY BEACON ACTIVE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ready to alert 108 & family guardians',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SECURE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Patient Switcher
            const Text(
              'PATIENT IN MEDICAL EMERGENCY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            const MemberSwitcher(),

            const SizedBox(height: 16),

            // 2. Central SOS Hold-to-Trigger Hub
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'URGENT RAPID RESPONSE HUB',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A), letterSpacing: 1),
                  ),
                  const SizedBox(height: 18),

                  // Giant Animated SOS Button
                  GestureDetector(
                    onTap: () => _makeCall('108'),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBA1A1A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBA1A1A).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emergency, color: Colors.white, size: 48),
                          const SizedBox(height: 4),
                          const Text(
                            'SOS 108',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            AppTranslations.tr(lang, 'callNow'),
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.tr(lang, 'callAmbulance'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Emergency Helplines Grid
            Text(
              AppTranslations.tr(lang, 'familyContacts'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _HelplineCard(
                    title: AppTranslations.tr(lang, 'actionFindHospital'),
                    number: '108',
                    icon: Icons.local_hospital,
                    color: const Color(0xFFBA1A1A),
                    onTap: () => _makeCall('108'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HelplineCard(
                    title: AppTranslations.tr(lang, 'callPolice'),
                    number: '100',
                    icon: Icons.local_police,
                    color: const Color(0xFF0284C7),
                    onTap: () => _makeCall('100'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HelplineCard(
                    title: 'Fire',
                    number: '101',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFD97706),
                    onTap: () => _makeCall('101'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. In Case of Emergency (ICE) Medical Card
            if (activeMember != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge, color: Color(0xFF00685F), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ICE Medical Card',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Blood: ${activeMember.bloodGroup}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Patient: ${activeMember.name} • ${activeMember.age} yrs (${activeMember.gender})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                    ),
                    if (activeMember.chronicConditions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chronic Conditions: ${activeMember.chronicConditions.join(", ")}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A), fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (activeMember.phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text('Direct Phone: ${activeMember.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA1A1A),
                          side: const BorderSide(color: Color(0xFFBA1A1A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.medical_information, size: 16),
                        label: const Text('Open Full Paramedic ICE Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => context.push('/dashboard/ice-card'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 5. Share Location Action
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00685F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.share_location, size: 20),
              label: Text(
                AppTranslations.tr(lang, 'shareLocation'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _shareLocation(context, activeMember?.name ?? "Family Member"),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelplineCard extends StatelessWidget {
  final String title;
  final String number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HelplineCard({
    required this.title,
    required this.number,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text(
              number,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
