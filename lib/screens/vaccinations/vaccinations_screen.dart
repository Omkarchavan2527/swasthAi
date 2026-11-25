import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/vaccination.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';
import '../../widgets/sw_card.dart';

class VaccinationsScreen extends ConsumerStatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  ConsumerState<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends ConsumerState<VaccinationsScreen> {
  String _selectedFilter = 'all'; // 'all', 'due', 'given'

  void _seedDefaultVaccinesIfEmpty(String memberId, String memberName) {
    final box = Hive.box<Vaccination>('vaccinations');
    final existing = box.values.where((v) => v.memberId == memberId).toList();
    if (existing.isEmpty) {
      final schedule = [
        {
          'name': 'BCG',
          'disease': 'Tuberculosis',
          'milestone': 'At Birth',
          'dueDate': '2024-01-15',
          'given': true,
          'givenDate': '2024-01-16',
        },
        {
          'name': 'Hepatitis B (Birth Dose)',
          'disease': 'Hepatitis B',
          'milestone': 'Within 24 Hours',
          'dueDate': '2024-01-15',
          'given': true,
          'givenDate': '2024-01-16',
        },
        {
          'name': 'OPV & Pentavalent-1',
          'disease': 'Polio, DPT, Hep B, Hib',
          'milestone': '6 Weeks',
          'dueDate': '2024-03-01',
          'given': true,
          'givenDate': '2024-03-02',
        },
        {
          'name': 'Pentavalent-2 & Rotavirus',
          'disease': 'DPT, Hep B, Diarrhea',
          'milestone': '10 Weeks',
          'dueDate': '2024-04-01',
          'given': true,
          'givenDate': '2024-04-05',
        },
        {
          'name': 'Measles & Rubella (MR-1)',
          'disease': 'Measles & Rubella',
          'milestone': '9-12 Months',
          'dueDate': '2026-11-15',
          'given': false,
          'givenDate': null,
        },
        {
          'name': 'DPT Booster 1',
          'disease': 'Diphtheria, Pertussis, Tetanus',
          'milestone': '16-24 Months',
          'dueDate': '2026-12-01',
          'given': false,
          'givenDate': null,
        },
        {
          'name': 'Annual Influenza / Flu Shot',
          'disease': 'Seasonal Flu',
          'milestone': 'Annual Booster',
          'dueDate': '2026-10-30',
          'given': false,
          'givenDate': null,
        },
      ];

      for (var item in schedule) {
        final id = const Uuid().v4();
        final v = Vaccination()
          ..id = id
          ..memberId = memberId
          ..memberName = memberName
          ..vaccineName = item['name'] as String
          ..diseaseProtected = item['disease'] as String
          ..dueDate = item['dueDate'] as String
          ..given = item['given'] as bool
          ..givenDate = item['givenDate'] as String?
          ..ageMilestone = item['milestone'] as String;
        box.put(id, v);
      }
    }
  }

  void _showAddVaccineDialog(BuildContext context, String memberId, String memberName) {
    final nameController = TextEditingController();
    final diseaseController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final milestoneController = TextEditingController(text: 'All Ages');
    bool isGiven = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              const Text(
                'Add Vaccine Record',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Vaccine Name *',
                  hintText: 'e.g., Td Booster, Hepatitis A',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.vaccines, color: Color(0xFF00685F)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diseaseController,
                decoration: InputDecoration(
                  labelText: 'Disease Protected Against',
                  hintText: 'e.g., Tetanus, Typhoid',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF00685F)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Due / Administered Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00685F)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: milestoneController,
                      decoration: InputDecoration(
                        labelText: 'Milestone / Target',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.alarm, color: Color(0xFF00685F)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF00685F),
                title: const Text('Already Administered?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Mark vaccine as completed', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                value: isGiven,
                onChanged: (val) => setSheetState(() => isGiven = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00685F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final id = const Uuid().v4();
                    final v = Vaccination()
                      ..id = id
                      ..memberId = memberId
                      ..memberName = memberName
                      ..vaccineName = name
                      ..diseaseProtected = diseaseController.text.trim().isNotEmpty
                          ? diseaseController.text.trim()
                          : 'General Immunization'
                      ..dueDate = dateController.text.trim()
                      ..given = isGiven
                      ..givenDate = isGiven ? dateController.text.trim() : null
                      ..ageMilestone = milestoneController.text.trim();

                    Hive.box<Vaccination>('vaccinations').put(id, v);
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added $name successfully!')),
                    );
                  },
                  child: const Text('Save Vaccine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final activeMember = ref.watch(activeMemberProvider);
    final box = Hive.box<Vaccination>('vaccinations');

    final memberId = activeMember?.id ?? '1';
    final memberName = activeMember?.name ?? 'Patient';

    _seedDefaultVaccinesIfEmpty(memberId, memberName);

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Vaccination> vaxBox, _) {
        final allVaxes = vaxBox.values.where((v) => v.memberId == memberId).toList();
        final filteredVaxes = allVaxes.where((v) {
          if (_selectedFilter == 'due') return !v.given;
          if (_selectedFilter == 'given') return v.given;
          return true;
        }).toList();

        final completedCount = allVaxes.where((v) => v.given).length;
        final totalCount = allVaxes.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              AppTranslations.tr(lang, 'vaccinesTitle'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
            ),
          ),
          body: Column(
            children: [
              const MemberSwitcher(),

              // Progress summary card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SWCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFF00685F), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Immunization Progress',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount of $totalCount vaccines received (${totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0}%)',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? (completedCount / totalCount) : 0,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: const Color(0xFF00685F),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All ($totalCount)',
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Due (${totalCount - completedCount})',
                      isSelected: _selectedFilter == 'due',
                      onTap: () => setState(() => _selectedFilter = 'due'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Given ($completedCount)',
                      isSelected: _selectedFilter == 'given',
                      onTap: () => setState(() => _selectedFilter = 'given'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: filteredVaxes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 56, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 10),
                            Text(
                              'No vaccine records found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: filteredVaxes.length,
                        itemBuilder: (context, index) {
                          final vax = filteredVaxes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SWCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vax.vaccineName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Protects against: ${vax.diseaseProtected}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          vax.given = !vax.given;
                                          if (vax.given) {
                                            vax.givenDate = DateTime.now().toString().substring(0, 10);
                                          } else {
                                            vax.givenDate = null;
                                          }
                                          vax.save();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                vax.given
                                                    ? '✓ Marked ${vax.vaccineName} as Administered'
                                                    : 'Marked ${vax.vaccineName} as Due',
                                              ),
                                              backgroundColor: vax.given ? const Color(0xFF00685F) : const Color(0xFFBA1A1A),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: vax.given ? const Color(0xFFCCFBF1) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: vax.given ? const Color(0xFF99F6E4) : const Color(0xFFFDE68A),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                vax.given ? Icons.check_circle : Icons.schedule,
                                                size: 13,
                                                color: vax.given ? const Color(0xFF00685F) : const Color(0xFFB45309),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                vax.given ? 'Given' : 'Due',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: vax.given ? const Color(0xFF00685F) : const Color(0xFFB45309),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        vax.given
                                            ? 'Given on: ${vax.givenDate ?? vax.dueDate}'
                                            : 'Due by: ${vax.dueDate}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          vax.ageMilestone,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00685F),
            foregroundColor: Colors.white,
            onPressed: () => _showAddVaccineDialog(context, memberId, memberName),
            icon: const Icon(Icons.add),
            label: const Text('Add Vaccine', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00685F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00685F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
