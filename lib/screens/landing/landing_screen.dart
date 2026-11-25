import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/settings_provider.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: lang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DropdownMenuItem(value: 'mr', child: Text('मराठी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(languageProvider.notifier).updateValue(v);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFCCFBF1), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1000685F),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.health_and_safety, size: 38, color: Color(0xFF00685F)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    AppTranslations.tr(lang, 'appTitle'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00685F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTranslations.tr(lang, 'appSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF121C2A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unified medical records, AI prescription scanner, vitals tracking & emergency SOS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Feature Cards
                  _buildFeatureCard(
                    Icons.medication,
                    AppTranslations.tr(lang, 'medicinesTitle'),
                    AppTranslations.tr(lang, 'medicinesSubtitle'),
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureCard(
                    Icons.document_scanner,
                    AppTranslations.tr(lang, 'actionScanPrescription'),
                    'Scan prescriptions with camera to auto-schedule doses and timings.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureCard(
                    Icons.monitor_heart,
                    AppTranslations.tr(lang, 'trendsTitle'),
                    'Track Blood Pressure, Blood Sugar, Heart Rate and oxygen vitals.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureCard(
                    Icons.emergency,
                    AppTranslations.tr(lang, 'emergencyTitle'),
                    'One-tap 108 national ambulance helpline & emergency family contacts.',
                  ),
                  const SizedBox(height: 32),

                  // Primary Actions
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00685F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.login, size: 20),
                      label: Text(
                        AppTranslations.tr(lang, 'signIn'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00685F),
                        side: const BorderSide(color: Color(0xFF00685F), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: Text(
                        AppTranslations.tr(lang, 'signUp'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.go('/signup'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security & Encryption note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Color(0xFF00685F)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${AppTranslations.tr(lang, 'securityVault')} • 256-Bit Encrypted',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00685F), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
