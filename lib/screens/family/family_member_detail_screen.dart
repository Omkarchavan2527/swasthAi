import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/family_provider.dart';
import '../../widgets/sw_card.dart';

class FamilyMemberDetailScreen extends ConsumerWidget {
  final String memberId;

  const FamilyMemberDetailScreen({Key? key, required this.memberId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final member = members.where((m) => m.id == memberId).firstOrNull;

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Member not found')),
      );
    }

    final accessCode = member.accessCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard/family'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF00685F),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(member.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF121C2A))),
            Text('${member.relationship} • Family Profile',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 16)),
            const SizedBox(height: 20),

            // Family Member Mobile Login Access Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00685F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x0C0F172A), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android, color: Color(0xFF00685F), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Mobile Login Access',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('No Password Needed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${member.name} can log into their health profile on their own phone using this unique code or by scanning this QR code.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Access Code Display Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MEMBER ACCESS CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              accessCode,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF00685F)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, color: Color(0xFF00685F), size: 22),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: accessCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Access Code $accessCode copied to clipboard!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Color(0xFF00685F), size: 22),
                              tooltip: 'Share Access Code',
                              onPressed: () {
                                Share.share(
                                  'Hi ${member.name}! Use this Family Access Code to log into your SwasthAI health profile on your mobile phone: $accessCode\n\nDownload the app and select "Family Member Access" on the login screen.',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: QrImageView(
                        data: accessCode,
                        version: QrVersions.auto,
                        size: 130,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Scan with SwasthAI Camera on their phone', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SWCard(
              child: Column(
                children: [
                  ListTile(
                      leading: const Icon(Icons.cake, color: Color(0xFF00685F)),
                      title: const Text('Age'),
                      trailing: Text('${member.age} years')),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.person, color: Color(0xFF00685F)),
                      title: const Text('Gender'),
                      trailing: Text(member.gender)),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.bloodtype, color: Color(0xFF00685F)),
                      title: const Text('Blood Group'),
                      trailing: Text(member.bloodGroup,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red))),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFF00685F)),
                      title: const Text('Phone'),
                      trailing: Text(member.phone.isNotEmpty ? member.phone : 'Not provided')),
                ],
              ),
            ),
            if (member.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 16),
              SWCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chronic Conditions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        children: member.chronicConditions
                            .map((c) => Chip(
                                  label: Text(c),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  labelStyle: const TextStyle(color: Colors.red),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.folder_shared, size: 18),
                    label: const Text('Medical Records'),
                    onPressed: () => context.go('/dashboard/records'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.medication, size: 18),
                    label: const Text('Medicines'),
                    onPressed: () => context.go('/dashboard/medicines'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
