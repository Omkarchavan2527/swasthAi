import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/medical_record.dart';
import '../../providers/family_provider.dart';
import '../../providers/medical_records_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';
import 'add_record_sheet.dart';

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';

  void _viewAttachment(BuildContext context, String filePath) async {
    final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');
    final isPdf = filePath.toLowerCase().contains('.pdf');

    if (isUrl) {
      final uri = Uri.parse(filePath);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening document in browser: $filePath')),
            );
          }
          await launchUrl(uri);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open document: $e')),
          );
        }
      }
    } else {
      // Local file on device storage
      final file = File(filePath);
      if (await file.exists()) {
        if (!isPdf) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.black87,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: Image.file(file),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          );
        } else {
          await OpenFilex.open(filePath);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found in local cache.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddRecordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRecordSheet(),
    );
  }

  void _confirmDeleteRecord(MedicalRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medical Record?'),
        content: Text('Are you sure you want to remove "${r.title}" from the cloud database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            onPressed: () {
              ref.read(recordsProvider.notifier).deleteRecord(r.memberId, r.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${r.title}"')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('lab')) return Icons.science;
    if (t.contains('prescription')) return Icons.medication;
    if (t.contains('vaccin')) return Icons.vaccines;
    if (t.contains('xray') || t.contains('x-ray') || t.contains('mri')) return Icons.biotech;
    return Icons.medical_services;
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(activeMemberRecordsProvider);
    final activeMember = ref.watch(activeMemberProvider);

    final filteredRecords = records.where((r) {
      if (_selectedCategory != 'all') {
        final rType = r.type.toLowerCase();
        if (_selectedCategory == 'prescription' && !rType.contains('prescription')) return false;
        if (_selectedCategory == 'lab' && !rType.contains('lab')) return false;
        if (_selectedCategory == 'visit' && !rType.contains('visit') && !rType.contains('doctor')) return false;
        if (_selectedCategory == 'vaccine' && !rType.contains('vaccin')) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = r.title.toLowerCase().contains(q);
        final matchDoc = (r.doctorName ?? '').toLowerCase().contains(q);
        final matchHosp = (r.hospitalName ?? '').toLowerCase().contains(q);
        return matchTitle || matchDoc || matchHosp;
      }
      return true;
    }).toList();

    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.tr(lang, 'recordsTitle'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121C2A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppTranslations.tr(lang, 'recordsSubtitle'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00685F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppTranslations.tr(lang, 'addRecord'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _showAddRecordSheet,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: AppTranslations.tr(lang, 'search'),
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Member Switcher Pill Carousel
            const MemberSwitcher(),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                children: [
                  _buildCatChip('${AppTranslations.tr(lang, 'filterAll')} (${records.length})', 'all'),
                  _buildCatChip(AppTranslations.tr(lang, 'filterPrescription'), 'prescription'),
                  _buildCatChip(AppTranslations.tr(lang, 'filterLab'), 'lab'),
                  _buildCatChip(AppTranslations.tr(lang, 'filterVisit'), 'visit'),
                  _buildCatChip(AppTranslations.tr(lang, 'filterVaccine'), 'vaccine'),
                ],
              ),
            ),

            // 256-bit Encryption Strip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF00685F), size: 14),
                  SizedBox(width: 6),
                  Text(
                    '256-bit AES Encrypted Health Repository',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF006F67)),
                  ),
                ],
              ),
            ),

            // Records List Stream
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(recordsProvider.notifier).loadRecords();
                },
                child: filteredRecords.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_shared_outlined, size: 54, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  records.isEmpty
                                      ? 'No medical records for ${activeMember?.name ?? "this patient"}'
                                      : 'No matching records found',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add doctor prescriptions, lab blood reports, and discharge notes.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF00685F)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add, color: Color(0xFF00685F), size: 18),
                                  label: const Text('Add First Record', style: TextStyle(color: Color(0xFF00685F))),
                                  onPressed: _showAddRecordSheet,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final r = filteredRecords[index];
                          return _buildRecordCard(r);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00685F),
        onPressed: _showAddRecordSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCatChip(String label, String key) {
    final isSelected = _selectedCategory == key;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: isSelected ? const Color(0xFFCCFBF1) : Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF006F67) : const Color(0xFFE2E8F0)),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF006F67) : const Color(0xFF121C2A),
          ),
        ),
        onPressed: () => setState(() => _selectedCategory = key),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(r.type), color: const Color(0xFF00685F), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.type.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              r.date,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _confirmDeleteRecord(r),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFBA1A1A)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient: ${r.memberName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (r.hospitalName != null || r.doctorName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, size: 14, color: Color(0xFF00685F)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${r.hospitalName ?? "Clinic"} • Dr. ${r.doctorName ?? "Consultant"}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 11, color: Color(0xFF006F67)),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 11, color: Color(0xFF00685F)),
                    SizedBox(width: 4),
                    Text(
                      'AI Summary Ready',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (r.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.insights, size: 16, color: Color(0xFF00685F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.details,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (r.attachedFilePaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (ctx) {
                final filePath = r.attachedFilePaths.first;
                final isPdf = filePath.toLowerCase().contains('.pdf');
                final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.image,
                          size: 16,
                          color: isPdf ? const Color(0xFFBA1A1A) : const Color(0xFF00685F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPdf ? 'Prescription / Lab PDF Report' : 'Prescription Document Image',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              isUrl ? 'Cloud Storage • Supabase' : 'Device Storage',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(50, 30),
                          backgroundColor: const Color(0xFF00685F).withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.visibility, size: 14, color: Color(0xFF00685F)),
                        label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                        onPressed: () => _viewAttachment(context, filePath),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
