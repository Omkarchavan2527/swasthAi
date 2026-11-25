import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/family_member.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  void _showAccessCodeModal(BuildContext context, FamilyMember m, [String lang = 'en']) {
    final code = m.accessCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_android, color: Color(0xFF00685F), size: 22),
                const SizedBox(width: 8),
                Text(
                  '${m.name} - ${AppTranslations.tr(lang, 'mobileLoginAccess')}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${m.name} ${AppTranslations.tr(lang, 'loginWithoutPassword')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00685F), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FAMILY ACCESS CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(
                        code,
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
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Code $code copied!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFF00685F), size: 22),
                        tooltip: 'Share Access Code',
                        onPressed: () {
                          Share.share(
                            'Hi ${m.name}! Use this Family Access Code to log into your SwasthAI health profile on your mobile phone: $code\n\nOpen the app and choose "Family Member Access" on the login screen.',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 130,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Scan with SwasthAI App on their mobile phone', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, [String lang = 'en']) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final conditionsController = TextEditingController();
    final phoneController = TextEditingController();
    String relationship = 'Mother';
    String bloodGroup = 'B+';
    String gender = 'Female';
    String? selectedCaretakerId;

    final existingMembers = ref.read(familyMembersProvider);

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
                  children: [
                    const Icon(Icons.person_add, color: Color(0xFF00685F), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.tr(lang, 'addFamilyMember'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121C2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Encrypted profile linked with family health records',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Quick Persona Picker Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _personaChip('Mother', 'Female', Icons.face_4, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                      _personaChip('Father', 'Male', Icons.face_6, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                      _personaChip('Spouse', 'Female', Icons.face_3, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                      _personaChip('Son', 'Male', Icons.child_care, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                      _personaChip('Daughter', 'Female', Icons.child_care, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                      _personaChip('Grandparent', 'Male', Icons.elderly, relationship, (r, g) {
                        setState(() { relationship = r; gender = g; });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Legal Name (as on Aadhaar) *',
                    hintText: 'e.g. Meena Sharma',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Age & Blood Group
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age (Years) *',
                          hintText: '58',
                          filled: true,
                          fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: bloodGroup,
                        decoration: InputDecoration(
                          labelText: 'Blood Group',
                          filled: true,
                          fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          isDense: true,
                        ),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                            .toList(),
                        onChanged: (v) => setState(() => bloodGroup = v ?? 'O+'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Conditions
                TextField(
                  controller: conditionsController,
                  decoration: InputDecoration(
                    labelText: 'Chronic Conditions (comma-separated)',
                    hintText: 'e.g. Hypertension, Type-2 Diabetes',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (for emergency SOS)',
                    hintText: '+91 98765 43210',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                  ),
                ),

                if (existingMembers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedCaretakerId,
                    decoration: InputDecoration(
                      labelText: 'Designate Caretaker from Family (Optional)',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No Caretaker (Self)')),
                      ...existingMembers.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text('${m.name} (${m.relationship})'))),
                    ],
                    onChanged: (v) => setState(() => selectedCaretakerId = v),
                  ),
                ],

                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Profile to Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final ageText = ageController.text.trim();

                      if (name.isEmpty || ageText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter full name and age')),
                        );
                        return;
                      }

                      await ref.read(familyMembersProvider.notifier).addMember(
                            name: name,
                            age: int.tryParse(ageText) ?? 25,
                            gender: gender,
                            relationship: relationship,
                            bloodGroup: bloodGroup,
                            chronicConditions: conditionsController.text.isNotEmpty
                                ? conditionsController.text.split(',').map((e) => e.trim()).toList()
                                : [],
                            phone: phoneController.text,
                            caretakerId: selectedCaretakerId,
                          );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added family profile "$name" successfully!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _personaChip(String label, String gender, IconData icon, String currentRel, Function(String, String) onSelect) {
    final isSel = currentRel == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onSelect(label, gender),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSel ? const Color(0xFF00685F) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSel ? const Color(0xFF00685F) : const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? const Color(0xFF00685F) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignCaretakerDialog(BuildContext context, WidgetRef ref, FamilyMember patient) {
    final members = ref.read(familyMembersProvider);
    final eligibleCaretakers = members.where((m) => m.id != patient.id).toList();
    String? selectedId = patient.caretakerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Designate Caretaker for ${patient.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When this member misses a medicine dose, the assigned caretaker receives a notification alert.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                value: selectedId,
                decoration: const InputDecoration(labelText: 'Select Caretaker', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None (Self Managed)')),
                  ...eligibleCaretakers.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text('${m.name} (${m.relationship})'))),
                ],
                onChanged: (v) => setState(() => selectedId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00685F), foregroundColor: Colors.white),
              onPressed: () async {
                await ref.read(familyMembersProvider.notifier).assignCaretaker(patient.id, selectedId);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caretaker assignment updated!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCaretakerDashboardModal(BuildContext context, WidgetRef ref) {
    final members = ref.read(familyMembersProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Color(0xFF00685F)),
                SizedBox(width: 8),
                Text('Caretaker Oversight Network', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Family members with designated caretakers for dose escalation.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ...members.map((m) {
              final ct = members.where((c) => c.id == m.caretakerId).firstOrNull;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFCCFBF1),
                  child: Text(m.name[0], style: const TextStyle(color: Color(0xFF00685F), fontWeight: FontWeight.bold)),
                ),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ct != null ? 'Caretaker: ${ct.name} (${ct.relationship})' : 'Self managed'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAssignCaretakerDialog(context, ref, m);
                  },
                  child: const Text('Change', style: TextStyle(color: Color(0xFF00685F))),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final activeMemberId = ref.watch(activeMemberIdProvider);
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
                  AppTranslations.tr(lang, 'familyTitle'),
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
                  child: Text('${members.length} ${AppTranslations.tr(lang, 'active')}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                ),
              ],
            ),
            Text(
              AppTranslations.tr(lang, 'familySubtitle'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFF00685F)),
            tooltip: AppTranslations.tr(lang, 'caretakers'),
            onPressed: () => _showCaretakerDashboardModal(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Caregiver Health Vault Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.security, color: Color(0xFF00685F), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.tr(lang, 'familySubtitle'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121C2A)),
                            ),
                            Text(
                              '${AppTranslations.tr(lang, 'securityVault')} • ${AppTranslations.tr(lang, 'verified')}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 12, color: Color(0xFF00685F)),
                          const SizedBox(width: 4),
                          Text(AppTranslations.tr(lang, 'verified'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.tr(lang, 'familySubtitle'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Registered Network Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr(lang, 'familyTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
              ),
              Text(
                '${members.length} ${AppTranslations.tr(lang, 'active')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Member Cards List
          if (members.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(AppTranslations.tr(lang, 'noFamilyMembers')),
              ),
            )
          else
            ...members.map((m) {
              final isActive = m.id == activeMemberId;
              final caretaker = members.where((c) => c.id == m.caretakerId).firstOrNull;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isActive ? const Color(0xFF00685F) : const Color(0xFFE2E8F0), width: isActive ? 1.5 : 1),
                  boxShadow: const [
                    BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isActive ? const Color(0xFF00685F) : const Color(0xFFF1F5F9),
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isActive ? Colors.white : const Color(0xFF00685F),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.relationship,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Age ${m.age} • Blood Group: ${m.bloodGroup} • ${m.gender}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                          onSelected: (val) {
                            if (val == 'caretaker') {
                              _showAssignCaretakerDialog(context, ref, m);
                            } else if (val == 'delete') {
                              ref.read(familyMembersProvider.notifier).deleteMember(m.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'caretaker', child: Text(AppTranslations.tr(lang, 'assignCaretaker'))),
                            PopupMenuItem(value: 'delete', child: Text(AppTranslations.tr(lang, 'deleteProfile'), style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Health Profile Identifier Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 14, color: Color(0xFF00685F)),
                              const SizedBox(width: 6),
                              Text(
                                '${AppTranslations.tr(lang, 'familyTitle')}: ${m.name}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 12, color: Color(0xFF00685F)),
                              const SizedBox(width: 4),
                              Text(AppTranslations.tr(lang, 'verified'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Family Member Mobile Login Access Code Pill
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00685F).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key, size: 14, color: Color(0xFF00685F)),
                              const SizedBox(width: 6),
                              Text(
                                '${AppTranslations.tr(lang, 'mobileAccessCode')}: ${m.accessCode}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _showAccessCodeModal(context, m, lang),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code, size: 14, color: Color(0xFF00685F)),
                                  const SizedBox(width: 4),
                                  Text('${AppTranslations.tr(lang, 'shareCode')} / QR', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Conditions & Caretaker Status
                    if (m.chronicConditions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: m.chronicConditions.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(c, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (caretaker != null)
                          Text(
                            '🛡️ ${AppTranslations.tr(lang, 'caretakers')}: ${caretaker.name}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF006F67), fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            AppTranslations.tr(lang, 'self'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        InkWell(
                          onTap: () {
                            ref.read(activeMemberIdProvider.notifier).state = m.id;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Switched active profile to ${m.name}')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF00685F) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? '${AppTranslations.tr(lang, 'active')} ✓' : AppTranslations.tr(lang, 'familyTitle'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xFF00685F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00685F),
        onPressed: () => _showAddMemberDialog(context, ref, lang),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(AppTranslations.tr(lang, 'addFamilyMember'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
