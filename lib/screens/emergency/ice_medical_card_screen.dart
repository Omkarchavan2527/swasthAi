import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/family_provider.dart';
import '../../providers/medicine_provider.dart';

class IceMedicalCardScreen extends ConsumerWidget {
  const IceMedicalCardScreen({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMember = ref.watch(activeMemberProvider);
    final medicines = ref.watch(activeMemberMedicinesProvider);
    final allMembers = ref.watch(familyMembersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.medical_information, color: Color(0xFFBA1A1A), size: 22),
            SizedBox(width: 8),
            Text(
              'ICE Emergency Medical Card',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF121C2A)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Paramedic Fast-Read Active Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paramedic Fast-Read Active',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF93000A)),
                      ),
                      Text(
                        'Immediate EMT triage view • No PIN needed',
                        style: TextStyle(fontSize: 11, color: Color(0xFF93000A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Patient Hero Card
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF00685F),
                  child: Text(
                    activeMember != null && activeMember.name.isNotEmpty
                        ? activeMember.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeMember?.name ?? 'Patient',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activeMember?.age ?? 45} Yrs • ${activeMember?.gender ?? "Male"} • English, Hindi',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vault ID: #SW-${activeMember?.id ?? "1001"} • Verified',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Blood Group Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'BLOOD',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      Text(
                        activeMember?.bloodGroup ?? 'O+',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Critical Medical Alerts Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6).withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Color(0xFFBA1A1A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'CRITICAL MEDICAL ALERTS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF93000A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Drug Allergies
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, size: 16, color: Color(0xFFBA1A1A)),
                          SizedBox(width: 6),
                          Text('KNOWN DRUG ALLERGIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFBA1A1A))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          Chip(
                            label: Text('Penicillin (Anaphylaxis Risk)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF93000A))),
                            backgroundColor: Color(0xFFFFDAD6),
                            padding: EdgeInsets.zero,
                          ),
                          Chip(
                            label: Text('Sulfa Drugs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF93000A))),
                            backgroundColor: Color(0xFFFFDAD6),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Chronic Conditions
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Color(0xFF00685F)),
                          SizedBox(width: 6),
                          Text('CHRONIC CONDITIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF121C2A))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: (activeMember?.chronicConditions.isNotEmpty ?? false)
                            ? activeMember!.chronicConditions.map((c) {
                                return Chip(
                                  label: Text(c, style: const TextStyle(fontSize: 11, color: Color(0xFF121C2A))),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  padding: EdgeInsets.zero,
                                );
                              }).toList()
                            : [
                                const Chip(
                                  label: Text('Hypertension', style: TextStyle(fontSize: 11)),
                                  backgroundColor: Color(0xFFF1F5F9),
                                  padding: EdgeInsets.zero,
                                ),
                                const Chip(
                                  label: Text('Type 2 Diabetes', style: TextStyle(fontSize: 11)),
                                  backgroundColor: Color(0xFFF1F5F9),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Critical Medications
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
                const Row(
                  children: [
                    Icon(Icons.medication, color: Color(0xFF00685F), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Active Critical Prescriptions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (medicines.isEmpty)
                  const Text('No daily prescriptions recorded.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                else
                  ...medicines.take(4).map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.medication, size: 16, color: Color(0xFF00685F)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A))),
                                Text('${m.dosage} • ${m.timing} • ${m.instructions}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Family Guardians / Contacts
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
                const Row(
                  children: [
                    Icon(Icons.contact_phone, color: Color(0xFF00685F), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Contacts (ICE)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...allMembers.where((m) => m.phone.isNotEmpty).map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m.name} (${m.relationship})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(m.phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF00685F)),
                          onPressed: () => _makeCall(m.phone),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
