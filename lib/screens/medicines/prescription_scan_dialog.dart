import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/family_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_prescription_scanner.dart';
import '../../services/notification_service.dart';
import '../../widgets/sw_card.dart';

class PrescriptionScanDialog extends ConsumerStatefulWidget {
  const PrescriptionScanDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrescriptionScanDialog(),
    );
  }

  @override
  ConsumerState<PrescriptionScanDialog> createState() =>
      _PrescriptionScanDialogState();
}

class _PrescriptionScanDialogState extends ConsumerState<PrescriptionScanDialog> {
  final AIPrescriptionScanner _scanner = AIPrescriptionScanner();
  File? _imageFile;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isValidPrescription = true;
  String? _rejectionReason;
  List<ExtractedMedicine> _extractedMeds = [];
  String? _selectedCaretakerId;
  String? _statusNote;

  @override
  void initState() {
    super.initState();
    // Auto-select current patient's assigned caretaker if present
    final activeMember = ref.read(activeMemberProvider);
    _selectedCaretakerId = activeMember?.caretakerId;
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await _scanner.pickPrescriptionImage(source);
    if (file == null) return;

    setState(() {
      _imageFile = file;
      _isAnalyzing = true;
      _statusNote = null;
      _rejectionReason = null;
      _isValidPrescription = true;
    });

    final apiKey = ref.read(geminiApiKeyProvider);

    try {
      final result = await _scanner.analyzePrescription(
        imageFile: file,
        apiKey: apiKey,
        preferredModel: ref.read(openrouterModelProvider),
      );

      setState(() {
        _extractedMeds = result.medicines;
        _statusNote = result.rawDoctorNote;
        _isValidPrescription = result.isValidPrescription;
        _rejectionReason = result.rejectionReason;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidPrescription = false;
        _rejectionReason = 'Error analyzing image: $e';
        _extractedMeds = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing prescription: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _scheduleAllMedicines() async {
    final selectedMeds = _extractedMeds.where((m) => m.isSelected).toList();
    if (selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one medicine to schedule.')),
      );
      return;
    }

    final activeMember = ref.read(activeMemberProvider);
    if (activeMember == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Assign Caretaker if chosen
      if (_selectedCaretakerId != null) {
        await ref
            .read(familyMembersProvider.notifier)
            .assignCaretaker(activeMember.id, _selectedCaretakerId);
      }

      // 2. Schedule each extracted medicine
      int scheduledCount = 0;
      for (final med in selectedMeds) {
        await ref.read(medicinesProvider.notifier).addMedicine(
              name: med.name.trim(),
              dosage: med.dosage.trim(),
              frequency: med.frequency,
              scheduledTimes: med.scheduledTimes,
              reminderBeforeMinutes: med.reminderBeforeMinutes,
              gracePeriodMinutes: med.gracePeriodMinutes,
              instructions: '${med.instructions} (AI Prescribed from Photo)',
            );

        // Schedule local notification reminder
        await NotificationService().showMedicineReminder(
          id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + scheduledCount,
          medicineName: med.name,
          scheduledTime: med.scheduledTimes.first,
          dosage: med.dosage,
          minutesBefore: med.reminderBeforeMinutes,
        );

        scheduledCount++;
      }

      // Refresh doses
      await ref.read(activeScheduledDosesProvider.notifier).loadDoses();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 AI successfully scheduled $scheduledCount medicines for ${activeMember.name}!',
            ),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medicines: $err')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(activeMemberProvider);
    final allMembers = ref.watch(familyMembersProvider);
    final lang = ref.watch(languageProvider);
    final eligibleCaretakers =
        allMembers.where((m) => m.id != activeMember?.id).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner,
                          color: Color(0xFF0D9488)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.tr(lang, 'scanPrescription'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${AppTranslations.tr(lang, 'familyTitle')}: ${activeMember?.name ?? "Patient"}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step 1: Capture / Upload Buttons if no image
            if (_imageFile == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.photo_camera_back_outlined,
                        size: 56, color: Color(0xFF0D9488)),
                    const SizedBox(height: 12),
                    const Text(
                      'Take a photo of your doctor\'s prescription',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI will automatically detect medicines, dosages, and scheduled times.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            label: const Text(
                              'Use Camera',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _pickAndAnalyze(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.photo_library,
                                color: Color(0xFF0D9488)),
                            label: const Text(
                              'From Gallery',
                              style: TextStyle(
                                  color: Color(0xFF0D9488),
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () =>
                                _pickAndAnalyze(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Step 2: Image Preview & Retake Option
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 16),
                          label: const Text('Retake',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          onPressed: () => _pickAndAnalyze(ImageSource.camera),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Status Loading or Note
              if (_isAnalyzing) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0D9488)),
                        SizedBox(height: 12),
                        Text(
                          'OpenRouter AI is analyzing prescription image...',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Detecting medicines, dosages, and schedule times',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (!_isValidPrescription || _extractedMeds.isEmpty) ...[
                // Rejection / Non-Prescription Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 10),
                      const Text(
                        'No Valid Prescription Detected',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _rejectionReason ??
                            'The uploaded image does not appear to be a doctor prescription or contain medical prescriptions. Please capture a clear, focused photo of an actual prescription.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F1D1D),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00685F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text(
                                'Retake Photo',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _pickAndAnalyze(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00685F),
                                side: const BorderSide(color: Color(0xFF00685F)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text(
                                'From Gallery',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (_statusNote != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusNote!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Extracted Medicines List
                Text(
                  'DETECTED MEDICINES (${_extractedMeds.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                ..._extractedMeds.map((med) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SWCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: med.isSelected,
                                activeColor: const Color(0xFF0D9488),
                                onChanged: (v) {
                                  setState(() => med.isSelected = v ?? true);
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  initialValue: med.name,
                                  decoration: const InputDecoration(
                                    labelText: 'Medicine Name & Strength',
                                    isDense: true,
                                    border: UnderlineInputBorder(),
                                  ),
                                  onChanged: (v) => med.name = v,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.dosage,
                                    decoration: const InputDecoration(
                                      labelText: 'Dosage',
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (v) => med.dosage = v,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: med.scheduledTimes.join(', '),
                                    decoration: const InputDecoration(
                                      labelText: 'Scheduled Times (HH:MM)',
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      med.scheduledTimes = v
                                          .split(',')
                                          .map((t) => t.trim())
                                          .where((t) => t.isNotEmpty)
                                          .toList();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 6),
                            child: Text(
                              'Instructions: ${med.instructions}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Caretaker Selection
                DropdownButtonFormField<String?>(
                  value: _selectedCaretakerId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Caretaker for Escalation',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.person_pin_circle, color: Color(0xFF0D9488)),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (No Caretaker)'),
                    ),
                    ...eligibleCaretakers.map((m) => DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text('${m.name} (${m.relationship})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCaretakerId = v),
                ),

                const SizedBox(height: 16),

                // Confirm & Schedule Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      _isSaving
                          ? 'Scheduling Medicines...'
                          : 'Confirm & Schedule with AI',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : _scheduleAllMedicines,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
