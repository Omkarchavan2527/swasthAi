import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sw_card.dart';

class MaternalCareScreen extends ConsumerStatefulWidget {
  const MaternalCareScreen({super.key});

  @override
  ConsumerState<MaternalCareScreen> createState() => _MaternalCareScreenState();
}

class _MaternalCareScreenState extends ConsumerState<MaternalCareScreen> {
  int _currentWeek = 20;
  final Map<String, bool> _checklist = {
    'iron_folic': true,
    'calcium_d3': false,
    'water_8_glasses': true,
    'kick_count': false,
    'walk_30min': false,
  };

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    try {
      final box = Hive.box('settings');
      _currentWeek = box.get('maternal_current_week', defaultValue: 20) as int;
      final savedChecklist = box.get('maternal_checklist_${DateTime.now().toString().substring(0, 10)}');
      if (savedChecklist != null && savedChecklist is Map) {
        savedChecklist.forEach((key, val) {
          if (_checklist.containsKey(key)) {
            _checklist[key as String] = val == true;
          }
        });
      }
    } catch (_) {}
  }

  void _updateWeek(int week) {
    setState(() => _currentWeek = week);
    try {
      Hive.box('settings').put('maternal_current_week', week);
    } catch (_) {}
  }

  void _toggleChecklistItem(String key, bool val) {
    setState(() => _checklist[key] = val);
    try {
      final box = Hive.box('settings');
      box.put('maternal_checklist_${DateTime.now().toString().substring(0, 10)}', _checklist);
    } catch (_) {}
  }

  String _getBabySizeAnalogy(int week) {
    if (week <= 4) return 'Poppy Seed (खसखस) • ~1 mm';
    if (week <= 8) return 'Kidney Bean (राजमा) • ~1.6 cm';
    if (week <= 12) return 'Lime / Lemon (लिंबू) • ~5.4 cm';
    if (week <= 16) return 'Avocado (बटर फ्रूट) • ~11.6 cm';
    if (week <= 20) return 'Banana (केळे) • ~25.6 cm • ~300g';
    if (week <= 24) return 'Corn Ear (कणीस) • ~30 cm • ~600g';
    if (week <= 28) return 'Eggplant / Brinjal (वांगी) • ~37 cm • ~1 kg';
    if (week <= 32) return 'Coconut (नारळ) • ~42 cm • ~1.7 kg';
    if (week <= 36) return 'Papaya (पपई) • ~47 cm • ~2.6 kg';
    return 'Full-term Watermelon (कलिंगड) • ~51 cm • ~3.4 kg';
  }

  String _getTrimester(int week) {
    if (week <= 12) return '1st Trimester (Weeks 1 - 12)';
    if (week <= 27) return '2nd Trimester (Weeks 13 - 27)';
    return '3rd Trimester (Weeks 28 - 40)';
  }

  String _getClinicalTip(int week) {
    if (week <= 12) {
      return 'Take Folic Acid daily to prevent neural tube defects. Drink tender coconut water to manage nausea and maintain electrolytes.';
    } else if (week <= 27) {
      return 'Time for anomaly scan (USG) around week 18-20. Ensure Iron + Calcium tablets (take separately with 2 hours gap for absorption).';
    } else {
      return 'Monitor fetal kick counts (aim for at least 10 movements in 2 hours). Watch for any sudden swelling in feet/face, or severe headaches.';
    }
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.tr(lang, 'maternalTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Pregnancy Week & Progress Card
          SWCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week $_currentWeek of 40',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTrimester(_currentWeek),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEC4899)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${40 - _currentWeek} wks to go',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDB2777)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _currentWeek / 40.0,
                    backgroundColor: const Color(0xFFFCE7F3),
                    color: const Color(0xFFEC4899),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change Week:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF00685F)),
                          onPressed: _currentWeek > 1 ? () => _updateWeek(_currentWeek - 1) : null,
                        ),
                        Text('$_currentWeek', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00685F)),
                          onPressed: _currentWeek < 40 ? () => _updateWeek(_currentWeek + 1) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Baby Growth Analogy Card
          SWCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.child_care, color: Color(0xFFE11D48), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Baby Size This Week',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getBabySizeAnalogy(_currentWeek),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Clinical Doctor Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getClinicalTip(_currentWeek),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A), height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Daily Mother & Baby Checklist
          SWCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist, color: Color(0xFF00685F), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Today\'s Mother & Baby Care Checklist',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('Iron & Folic Acid Tablet (IFA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Prevents maternal anemia & birth defects', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _checklist['iron_folic'] ?? false,
                  onChanged: (v) => _toggleChecklistItem('iron_folic', v ?? false),
                ),
                const Divider(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('Calcium & Vitamin D3 Tablet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Take 2 hrs apart from Iron for bone development', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _checklist['calcium_d3'] ?? false,
                  onChanged: (v) => _toggleChecklistItem('calcium_d3', v ?? false),
                ),
                const Divider(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('8-10 Glasses Clean Water', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Maintains amniotic fluid & hydration', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _checklist['water_8_glasses'] ?? false,
                  onChanged: (v) => _toggleChecklistItem('water_8_glasses', v ?? false),
                ),
                const Divider(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('Fetal Movement / Kick Count Checked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('At least 10 active kicks in 2 hours', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _checklist['kick_count'] ?? false,
                  onChanged: (v) => _toggleChecklistItem('kick_count', v ?? false),
                ),
                const Divider(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF00685F),
                  title: const Text('Gentle 20-30 min Walk or Rest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _checklist['walk_30min'] ?? false,
                  onChanged: (v) => _toggleChecklistItem('walk_30min', v ?? false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Emergency Red Flags Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Warning Signs (Seek Immediate Medical Care)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Vaginal bleeding or fluid leakage\n'
                  '• Severe headache with blurred vision (Pre-eclampsia)\n'
                  '• Sudden swelling in face, hands, or feet\n'
                  '• Absence of baby kicks/movements for > 12 hours\n'
                  '• High fever with chills or severe abdominal cramps',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D), height: 1.4),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call 108 Emergency Ambulance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _callHelpline('108'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
