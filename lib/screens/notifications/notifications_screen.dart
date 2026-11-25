import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/family_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../services/cloud_sync_service.dart';
import '../../widgets/member_switcher.dart';
import '../../widgets/sw_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _caretakerAlerts = [];
  bool _isLoadingAlerts = false;

  @override
  void initState() {
    super.initState();
    _fetchCaretakerAlerts();
  }

  Future<void> _fetchCaretakerAlerts() async {
    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return;

    setState(() => _isLoadingAlerts = true);
    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      final dashboard = await cloudService.fetchCaretakerDashboard(activeMember.id);
      if (dashboard != null && dashboard['notifications'] != null) {
        setState(() {
          _caretakerAlerts = List<Map<String, dynamic>>.from(dashboard['notifications']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingAlerts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(activeMemberProvider);
    final doses = ref.watch(activeScheduledDosesProvider);

    final pendingDoses = doses.where((d) => !d.isTaken).toList();
    final takenDoses = doses.where((d) => d.isTaken).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders & Alerts'),
        bottom: _isLoadingAlerts
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF0D9488),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(activeScheduledDosesProvider.notifier).loadDoses();
              _fetchCaretakerAlerts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed reminders & caretaker alerts!')),
              );
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
                await ref.read(activeScheduledDosesProvider.notifier).loadDoses();
                await _fetchCaretakerAlerts();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Caretaker Escalation Alerts Section
                  if (_caretakerAlerts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'CARETAKER ESCALATION ALERTS (${_caretakerAlerts.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._caretakerAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SWCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEE2E2),
                                child: Icon(Icons.notifications_active, color: Colors.red),
                              ),
                              title: Text(
                                alert['message'] ?? 'Patient dose not confirmed!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              subtitle: Text(
                                'Scheduled for: ${alert['scheduled_time'] ?? "Today"}\nStatus: ${alert['status'] ?? "Unread"}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // 2. Patient Today Medicine Reminders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MEDICINE DOSE REMINDERS (${activeMember?.name ?? 'Profile'})",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9488),
                          letterSpacing: 1,
                        ),
                      ),
                      if (pendingDoses.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingDoses.length} Pending',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (pendingDoses.isEmpty && _caretakerAlerts.isEmpty && takenDoses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'All Caught Up!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No pending medicine reminders or missed alerts for ${activeMember?.name ?? "this profile"}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Pending / Due Reminders
                    ...pendingDoses.map((dose) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SWCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          dose.isMissed
                                              ? Icons.warning
                                              : (dose.isOverdue
                                                  ? Icons.access_time_filled
                                                  : Icons.alarm),
                                          color: dose.isMissed
                                              ? Colors.red
                                              : (dose.isOverdue
                                                  ? Colors.amber[800]
                                                  : const Color(0xFF0D9488)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '⏰ ${dose.scheduledTime} - ${dose.medicineName}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: dose.isMissed
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dose.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: dose.isMissed
                                              ? Colors.red
                                              : const Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Dosage: ${dose.dosage}${dose.instructions != null && dose.instructions!.isNotEmpty ? " • ${dose.instructions}" : ""}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                    label: const Text(
                                      '✓ Mark as Taken',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(activeScheduledDosesProvider.notifier)
                                          .markDoseTaken(dose.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '✓ Marked ${dose.medicineName} as taken!'),
                                          backgroundColor: const Color(0xFF0D9488),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),

                    // Completed Doses
                    if (takenDoses.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "COMPLETED MEDICINES TODAY",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...takenDoses.map((dose) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SWCard(
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(
                                  '${dose.medicineName} (${dose.dosage})',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  'Taken at ${DateTime.tryParse(dose.takenAt ?? "")?.toLocal().toString().substring(11, 16) ?? dose.scheduledTime}',
                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ),
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
    );
  }
}
