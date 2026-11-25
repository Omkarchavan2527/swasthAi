import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAiKeyDialog(BuildContext context, WidgetRef ref) {
    final currentKey = ref.read(geminiApiKeyProvider);
    final keyController = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Color(0xFF00685F)),
            SizedBox(width: 8),
            Text('OpenRouter AI API Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your OpenRouter key (starts with sk-or-...) or Google Gemini key (starts with AIza...).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-or-v1-...',
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00685F), foregroundColor: Colors.white),
            onPressed: () {
              ref.read(aiApiKeyProvider.notifier).updateValue(keyController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Key saved successfully! AI Assistant ready.')),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _showAiModelDialog(BuildContext context, WidgetRef ref) {
    final currentModel = ref.read(openrouterModelProvider);
    final customController = TextEditingController(text: currentModel);

    final popularModels = [
      {'id': 'google/gemini-2.0-flash-001', 'name': 'Gemini 2.0 Flash (Recommended)'},
      {'id': 'google/gemini-flash-1.5', 'name': 'Gemini 1.5 Flash'},
      {'id': 'google/gemini-2.0-flash-lite-001', 'name': 'Gemini 2.0 Flash Lite (Fast)'},
      {'id': 'openrouter/auto', 'name': 'OpenRouter Auto (Automatic Routing)'},
      {'id': 'openai/gpt-4o-mini', 'name': 'GPT-4o Mini'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select AI Model Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active model for OpenRouter key:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              ...popularModels.map((m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      m['id'] == currentModel ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: const Color(0xFF00685F),
                      size: 20,
                    ),
                    title: Text(m['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(m['id']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: () {
                      ref.read(openrouterModelProvider.notifier).updateValue(m['id']!);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Model set to ${m['name']}')),
                      );
                    },
                  )),
              const Divider(),
              const Text('Or Custom Model ID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: customController,
                decoration: InputDecoration(
                  hintText: 'e.g. google/gemini-2.5-flash',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00685F), foregroundColor: Colors.white),
            onPressed: () {
              if (customController.text.trim().isNotEmpty) {
                ref.read(openrouterModelProvider.notifier).updateValue(customController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Model'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(AppTranslations.tr(lang, 'logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          AppTranslations.tr(lang, 'logoutConfirm'),
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppTranslations.tr(lang, 'cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final settingsBox = Hive.box('settings');
              await settingsBox.put('is_logged_in', false);
              await settingsBox.delete('active_user_id');
              await settingsBox.delete('user_phone');
              await settingsBox.flush();
              ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/landing');
              }
            },
            child: Text(AppTranslations.tr(lang, 'logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isElderly = ref.watch(elderlyModeProvider);
    final isLowLit = ref.watch(lowLiteracyModeProvider);
    final authState = ref.watch(authProvider);
    final apiKey = ref.watch(geminiApiKeyProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.getCurrentUser();
    final selectedModel = ref.watch(openrouterModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.tr(lang, 'settingsTitle'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
            ),
            Text(
              AppTranslations.tr(lang, 'settingsSubtitle'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Account Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF00685F),
                          child: Text(
                            (currentUser?.fullName.isNotEmpty ?? false)
                                ? currentUser!.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                            child: const Icon(Icons.verified, size: 12, color: Colors.white),
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
                            currentUser?.fullName ?? (authState.familyMemberName ?? 'User'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser?.email ?? authState.phoneNumber ?? '+91 98765 43210',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppTranslations.tr(lang, 'securityVault')} • ${AppTranslations.tr(lang, 'verified')}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF00685F)),
                          const SizedBox(width: 6),
                          Text(AppTranslations.tr(lang, 'securityVault'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF121C2A))),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(AppTranslations.tr(lang, 'active'), style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Encryption Assurance Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00685F).withOpacity(0.08),
                  const Color(0xFFCCFBF1).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00685F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.enhanced_encryption, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.tr(lang, 'securityVault'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Private records remain exclusively protected with secure 256-bit encryption.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. AI Assistant Settings Section
          _buildSectionHeader(AppTranslations.tr(lang, 'assistantTitle')),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'aiKey'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    apiKey.isNotEmpty
                        ? 'Configured (${apiKey.substring(0, apiKey.length > 8 ? 8 : apiKey.length)}...)'
                        : 'Tap to configure key for AI Doctor & Scanner',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _showAiKeyDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.model_training, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'aiModel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('$selectedModel (Tap to change)', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAiModelDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Cloud Backup & Sync Section
          _buildSectionHeader(AppTranslations.tr(lang, 'cloudSync')),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_done, color: Color(0xFF059669)),
                  title: Text(
                    AppTranslations.tr(lang, 'cloudSync'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Live Cloud Database Sync',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      AppTranslations.tr(lang, 'online'),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF00685F),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'syncNow'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    authState.isSyncing
                        ? AppTranslations.tr(lang, 'loading')
                        : 'Last synced: ${authState.lastSyncedAt?.toString().substring(0, 16) ?? "Today"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: authState.isSyncing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCCFBF1),
                            foregroundColor: const Color(0xFF006F67),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () async {
                            await ref.read(cloudSyncServiceProvider).syncAllData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cloud sync completed successfully!')),
                              );
                            }
                          },
                          child: Text(AppTranslations.tr(lang, 'syncNow'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Accessibility & Regional Languages
          _buildSectionHeader(AppTranslations.tr(lang, 'language')),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    lang == 'hi' ? 'हिंदी (Hindi)' : lang == 'mr' ? 'मराठी (Marathi)' : 'English',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButton<String>(
                    value: lang,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                      DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(languageProvider.notifier).updateValue(v);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.text_fields, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'elderlyMode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Increases font size across all modules', style: TextStyle(fontSize: 12)),
                  value: isElderly,
                  activeColor: const Color(0xFF00685F),
                  onChanged: (v) => ref.read(elderlyModeProvider.notifier).updateValue(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over, color: Color(0xFF00685F)),
                  title: Text(AppTranslations.tr(lang, 'lowLiteracyMode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Enables audio prompts and simplified icons', style: TextStyle(fontSize: 12)),
                  value: isLowLit,
                  activeColor: const Color(0xFF00685F),
                  onChanged: (v) => ref.read(lowLiteracyModeProvider.notifier).updateValue(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Logout
          _buildSectionHeader(AppTranslations.tr(lang, 'logout')),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                  title: Text(AppTranslations.tr(lang, 'logout'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFBA1A1A))),
                  subtitle: const Text('Sign out of your active session', style: TextStyle(fontSize: 12)),
                  onTap: () => _showLogoutConfirmDialog(context, ref, lang),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Version note
          Center(
            child: Text(
              '${AppTranslations.tr(lang, 'appTitle')} • Version 2.2.0\n${AppTranslations.tr(lang, 'securityVault')} • 256-Bit Encrypted',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00685F),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
