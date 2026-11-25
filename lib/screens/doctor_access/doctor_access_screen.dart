import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/cloud_sync_service.dart';
import '../../widgets/member_switcher.dart';

class ActiveSharingSessionItem {
  final String id;
  final String patientName;
  final String rawToken;
  final String otp;
  final String qrUrl;
  final String expiresAt;

  ActiveSharingSessionItem({
    required this.id,
    required this.patientName,
    required this.rawToken,
    required this.otp,
    required this.qrUrl,
    required this.expiresAt,
  });
}

class DoctorAccessScreen extends ConsumerStatefulWidget {
  const DoctorAccessScreen({super.key});

  @override
  ConsumerState<DoctorAccessScreen> createState() => _DoctorAccessScreenState();
}

class _DoctorAccessScreenState extends ConsumerState<DoctorAccessScreen> {
  int _selectedDuration = 120; // 2 hours
  String? _currentOtp;
  String? _currentQrUrl;
  String? _currentSessionId;
  bool _isGenerating = false;

  // Category permissions
  bool _shareMedicalHistory = true;
  bool _shareCurrentMedicines = true;
  bool _sharePrescriptions = true;
  bool _shareLabReports = true;
  bool _shareVaccinations = true;

  final List<ActiveSharingSessionItem> _activeSessions = [];

  Future<void> _generateDoctorSharingSession() async {
    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return;

    setState(() => _isGenerating = true);

    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      final categories = {
        'medicalHistory': _shareMedicalHistory,
        'currentMedicines': _shareCurrentMedicines,
        'prescriptions': _sharePrescriptions,
        'labReports': _shareLabReports,
        'vaccinationHistory': _shareVaccinations,
      };

      final sessionResult = await cloudService.createDoctorSharingSession(
        profileId: activeMember.id,
        patientName: activeMember.name,
        durationMinutes: _selectedDuration,
        categories: categories,
      );

      if (sessionResult != null) {
        final item = ActiveSharingSessionItem(
          id: sessionResult.id,
          patientName: activeMember.name,
          rawToken: sessionResult.rawToken,
          otp: sessionResult.otp,
          qrUrl: sessionResult.qrUrl,
          expiresAt: sessionResult.expiresAt,
        );

        setState(() {
          _currentOtp = sessionResult.otp;
          _currentQrUrl = sessionResult.qrUrl;
          _currentSessionId = sessionResult.id;
          _activeSessions.insert(0, item);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generated Doctor Access QR for ${activeMember.name}!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    final cloudService = ref.read(cloudSyncServiceProvider);
    await cloudService.revokeDoctorSharingSession(sessionId);

    setState(() {
      _activeSessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        _currentOtp = null;
        _currentQrUrl = null;
        _currentSessionId = null;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing session revoked. Doctor access link invalidated.')),
      );
    }
  }

  void _showAuditLogModal() async {
    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return;

    final cloudService = ref.read(cloudSyncServiceProvider);
    final logs = await cloudService.fetchDoctorAuditLogs(activeMember.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Access Audit Trail (${activeMember.name})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No external clinical views recorded yet.', style: TextStyle(color: Color(0xFF64748B))),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    final doctorId = log['doctor_identifier']?.toString() ?? 'In-Clinic Physician Access';
                    final ip = log['ip_address']?.toString() ?? 'Local Network';
                    final viewedAt = log['created_at']?.toString() ?? log['viewed_at']?.toString() ?? 'Recently';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.visibility, color: Color(0xFF00685F)),
                      title: Text(doctorId),
                      subtitle: Text('IP: $ip • $viewedAt'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(activeMemberProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.tr(lang, 'doctorAccessTitle'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(AppTranslations.tr(lang, 'verified'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                ),
              ],
            ),
            Text(
              AppTranslations.tr(lang, 'securityVault'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF00685F)),
            onPressed: _showAuditLogModal,
            tooltip: 'Audit Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Member Switcher
          const MemberSwitcher(),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Hero QR Code Container
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status Badge & Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00685F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'In-Clinic Session Ready',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 14, color: Color(0xFF00685F)),
                                const SizedBox(width: 4),
                                Text(
                                  'Valid: ${_selectedDuration}m',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // QR Code Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 4),
                          ],
                        ),
                        child: _currentQrUrl != null
                            ? QrImageView(
                                data: _currentQrUrl!,
                                version: QrVersions.auto,
                                size: 190,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF121C2A)),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF121C2A)),
                              )
                            : Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap "Generate Session"\nto create doctor QR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hold steady for doctor\'s camera or clinical tablet',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Session ID & Doctor Decrypt PIN Grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SESSION ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _currentSessionId != null ? _currentSessionId!.substring(0, 8).toUpperCase() : 'SW-PENDING',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                                      ),
                                      if (_currentSessionId != null)
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: _currentSessionId!));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session ID copied')));
                                          },
                                          child: const Icon(Icons.copy, size: 14, color: Color(0xFF00685F)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCCFBF1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DOCTOR DECRYPT PIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentOtp ?? '••••',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00685F), letterSpacing: 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Share / Refresh Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00685F),
                                side: const BorderSide(color: Color(0xFF00685F)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.sync, size: 18),
                              label: const Text('Refresh QR', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _isGenerating ? null : _generateDoctorSharingSession,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00685F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _currentQrUrl != null
                                  ? () {
                                      Share.share(
                                        'SwasthAI Doctor Access Link for ${activeMember?.name ?? "Patient"}:\n'
                                        '$_currentQrUrl\n\n'
                                        'Use Doctor PIN: ${_currentOtp ?? "Contact patient"}\n'
                                        '(Valid for $_selectedDuration minutes with secure OTP)',
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Granular Permissions Checklist
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
                      const Text(
                        'Select Records to Share',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Choose which encrypted records are accessible during consultation',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      _buildCheckTile('Medical History & Diagnoses', _shareMedicalHistory, (v) => setState(() => _shareMedicalHistory = v!)),
                      _buildCheckTile('Active Medications & Dosages', _shareCurrentMedicines, (v) => setState(() => _shareCurrentMedicines = v!)),
                      _buildCheckTile('Doctor Prescriptions', _sharePrescriptions, (v) => setState(() => _sharePrescriptions = v!)),
                      _buildCheckTile('Laboratory Diagnostic Reports', _shareLabReports, (v) => setState(() => _shareLabReports = v!)),
                      _buildCheckTile('Vaccination Records', _shareVaccinations, (v) => setState(() => _shareVaccinations = v!)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Duration Selector
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
                      const Text(
                        'Session Validity Duration',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [30, 60, 120, 240, 1440].map((mins) {
                            final isSel = _selectedDuration == mins;
                            final label = mins >= 60 ? '${mins ~/ 60} Hour${mins ~/ 60 > 1 ? "s" : ""}' : '$mins Mins';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: isSel,
                                selectedColor: const Color(0xFF00685F),
                                backgroundColor: const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : const Color(0xFF121C2A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedDuration = mins);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.qr_code),
                    label: Text(
                      _isGenerating ? 'Generating Access Token...' : 'Generate New Doctor Session',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _isGenerating ? null : _generateDoctorSharingSession,
                  ),
                ),
                const SizedBox(height: 24),

                // Active Sessions List
                if (_activeSessions.isNotEmpty) ...[
                  const Text(
                    'Active Doctor Sessions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                  ),
                  const SizedBox(height: 10),
                  ..._activeSessions.map((s) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code, color: Color(0xFF00685F), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient: ${s.patientName} (PIN: ${s.otp})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Expires: ${s.expiresAt.substring(11, 16)}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _revokeSession(s.id),
                            child: Text(AppTranslations.tr(lang, 'revokeAccess'), style: const TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              activeColor: const Color(0xFF00685F),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
