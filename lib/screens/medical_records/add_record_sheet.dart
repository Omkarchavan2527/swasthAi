import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/medical_record.dart';
import '../../providers/family_provider.dart';
import '../../providers/medical_records_provider.dart';
import '../../providers/settings_provider.dart';

class AddRecordSheet extends ConsumerStatefulWidget {
  const AddRecordSheet({super.key});

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _detailsController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now().toString().substring(0, 10),
  );

  String _selectedType = 'Prescription';
  final List<Map<String, dynamic>> _types = [
    {'name': 'Prescription', 'icon': Icons.medication},
    {'name': 'Lab Report', 'icon': Icons.science},
    {'name': 'Doctor Visit', 'icon': Icons.medical_services},
    {'name': 'X-Ray / MRI', 'icon': Icons.biotech},
    {'name': 'Vaccination', 'icon': Icons.vaccines},
  ];

  String? _attachedFilePath;
  String? _attachedFileName;
  bool _isPdf = false;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _attachedFilePath = picked.path;
          _attachedFileName = picked.name;
          _isPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error choosing image: $e')));
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _attachedFilePath = file.path;
            _attachedFileName = file.name;
            _isPdf = file.name.toLowerCase().endsWith('.pdf');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final activeMember = ref.read(activeMemberProvider);
        final memberId = activeMember?.id ?? '1';
        final memberName = activeMember?.name ?? 'Patient';

        final record = MedicalRecord()
          ..id = const Uuid().v4()
          ..memberId = memberId
          ..memberName = memberName
          ..type = _selectedType.toLowerCase().replaceAll(' ', '_')
          ..title = _titleController.text.trim()
          ..date = _dateController.text.trim()
          ..doctorName = _doctorController.text.trim().isNotEmpty ? _doctorController.text.trim() : null
          ..hospitalName = _hospitalController.text.trim().isNotEmpty ? _hospitalController.text.trim() : null
          ..diagnosis = _titleController.text.trim()
          ..details = _detailsController.text.trim()
          ..tags = [_selectedType]
          ..attachedFilePaths = _attachedFilePath != null ? [_attachedFilePath!] : [];

        await ref.read(recordsProvider.notifier).addRecord(record);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_attachedFilePath != null
                  ? 'Record "${record.title}" & file uploaded securely to Cloud Vault! ✓'
                  : 'Medical Record "${record.title}" added to vault! ✓'),
              backgroundColor: const Color(0xFF00685F),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save record: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(activeMemberProvider);
    final lang = ref.watch(languageProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppTranslations.tr(lang, 'addRecord'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(AppTranslations.tr(lang, 'verified'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                          ),
                        ],
                      ),
                      Text(
                        '${AppTranslations.tr(lang, 'familyTitle')}: ${activeMember?.name ?? "Family Member"}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Choice Chips
              const Text('RECORD CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((t) {
                    final isSel = _selectedType == t['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(t['icon'] as IconData, size: 14, color: isSel ? Colors.white : const Color(0xFF00685F)),
                        label: Text(t['name'] as String),
                        selected: isSel,
                        selectedColor: const Color(0xFF00685F),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : const Color(0xFF334155),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedType = t['name'] as String);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title / Diagnosis *',
                  hintText: 'e.g. Apollo Health Checkup / Lipid Panel',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  prefixIcon: const Icon(Icons.title, size: 18, color: Color(0xFF00685F)),
                  isDense: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a record title' : null,
              ),
              const SizedBox(height: 12),

              // Doctor & Hospital Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _doctorController,
                      decoration: InputDecoration(
                        labelText: 'Consulting Doctor',
                        hintText: 'Dr. Sharma',
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
                    child: TextFormField(
                      controller: _hospitalController,
                      decoration: InputDecoration(
                        labelText: 'Hospital / Clinic',
                        hintText: 'Apollo Clinic',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Record Date (YYYY-MM-DD)',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF00685F)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Notes / Clinical Details
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Clinical Notes & Findings',
                  hintText: 'Enter test findings, doctor advice, or prescription notes...',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 16),

              // Attachment Section (Image or PDF)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ATTACH DOCUMENT (PHOTO OR PDF)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F)),
                  ),
                  if (_attachedFilePath != null)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                      onPressed: () => setState(() {
                        _attachedFilePath = null;
                        _attachedFileName = null;
                      }),
                      child: const Text('Remove', style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_attachedFilePath == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00685F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.photo_camera, size: 16, color: Color(0xFF00685F)),
                          label: const Text('Camera', style: TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.bold)),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00685F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFF00685F)),
                          label: const Text('Gallery', style: TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.bold)),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00685F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF00685F)),
                          label: const Text('PDF / File', style: TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.bold)),
                          onPressed: _pickDocument,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00685F)),
                  ),
                  child: Row(
                    children: [
                      if (_isPdf)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFBA1A1A), size: 28),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_attachedFilePath!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachedFileName ?? (_isPdf ? 'Prescription Report.pdf' : 'Prescription Photo.jpg'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPdf ? 'PDF Report ready for Cloud Database' : 'Image ready for Cloud Database',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF00685F), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        onPressed: () => setState(() {
                          _attachedFilePath = null;
                          _attachedFileName = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00685F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: Text(
                    _isSaving ? AppTranslations.tr(lang, 'loading') : AppTranslations.tr(lang, 'save'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _isSaving ? null : _saveRecord,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
