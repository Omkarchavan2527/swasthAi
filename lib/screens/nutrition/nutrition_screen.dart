import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';
import '../../widgets/sw_card.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  int _waterGlasses = 4;
  final int _targetGlasses = 10;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  void _loadWater() {
    try {
      final box = Hive.box('settings');
      final today = DateTime.now().toString().substring(0, 10);
      final activeId = ref.read(activeMemberProvider)?.id ?? '1';
      _waterGlasses = box.get('water_intake_${today}_$activeId', defaultValue: 4) as int;
    } catch (_) {}
  }

  void _updateWater(int delta) {
    final newCount = (_waterGlasses + delta).clamp(0, 20);
    setState(() => _waterGlasses = newCount);
    try {
      final box = Hive.box('settings');
      final today = DateTime.now().toString().substring(0, 10);
      final activeId = ref.read(activeMemberProvider)?.id ?? '1';
      box.put('water_intake_${today}_$activeId', newCount);
    } catch (_) {}
  }

  int _calculateCalorieTarget(int age, String gender) {
    if (gender == 'Male') {
      if (age < 18) return 2400;
      if (age < 50) return 2200;
      return 1900;
    } else {
      if (age < 18) return 2000;
      if (age < 50) return 1850;
      return 1650;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final activeMember = ref.watch(activeMemberProvider);

    final age = activeMember?.age ?? 45;
    final gender = activeMember?.gender ?? 'Male';
    final conditions = activeMember?.chronicConditions ?? [];
    final targetCalories = _calculateCalorieTarget(age, gender);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.tr(lang, 'nutritionTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MemberSwitcher(),
          const SizedBox(height: 12),

          // 1. Daily Targets Overview Card
          SWCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      AppTranslations.tr(lang, 'dailyCalories'),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$targetCalories kcal',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target for ${activeMember?.name ?? "Patient"}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(width: 1, height: 48, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    const Text(
                      'Water Hydration',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_waterGlasses * 0.25).toStringAsFixed(1)} / 2.5 L',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_waterGlasses / $_targetGlasses glasses',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Interactive Water Tracker
          SWCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop, color: Color(0xFF0284C7), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Today\'s Hydration Tracker',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _waterGlasses >= _targetGlasses ? const Color(0xFFCCFBF1) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _waterGlasses >= _targetGlasses ? 'Goal Reached!' : '${_targetGlasses - _waterGlasses} glasses left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _waterGlasses >= _targetGlasses ? const Color(0xFF00685F) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_waterGlasses / _targetGlasses).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE0F2FE),
                    color: const Color(0xFF0284C7),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('1 Glass (250ml)'),
                      onPressed: () => _updateWater(-1),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ 1 Glass (250ml)'),
                      onPressed: () => _updateWater(1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Condition-Specific Dietary Guidelines
          if (conditions.any((c) => c.toLowerCase().contains('diabet') || c.toLowerCase().contains('sugar')))
            _buildSpecialDietAlert(
              title: 'Diabetic Dietary Guidance',
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              icon: Icons.grain,
              tips: [
                'Choose complex carbs: Jowar, Bajra bhakri instead of polished white rice.',
                'Include Methi (fenugreek) seeds and Karela (bitter gourd) in weekly diet.',
                'Eat whole fresh fruits (guava, apple) instead of fruit juices.',
                'Avoid sweets, sweetened tea/chai, and bakery items.',
              ],
            ),

          if (conditions.any((c) => c.toLowerCase().contains('hyper') || c.toLowerCase().contains('bp') || c.toLowerCase().contains('pressure')))
            _buildSpecialDietAlert(
              title: 'Hypertension (BP) Salt Restriction Guide',
              color: const Color(0xFFBA1A1A),
              bgColor: const Color(0xFFFEE2E2),
              icon: Icons.favorite_outline,
              tips: [
                'Strictly limit salt to under 1 level teaspoon (< 5g) per day.',
                'Avoid high-sodium foods: Papad, pickles (लोणचे), packaged namkeen, and canned soups.',
                'Increase potassium: Bananas, spinach (पालक), coconut water, and pumpkin seeds.',
                'Cook with garlic, ginger, and lemon to flavor food without extra salt.',
              ],
            ),

          const SizedBox(height: 14),

          // 4. Balanced Indian Thali Breakdown
          const Text(
            'The Healthy Indian Thali Rule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
          ),
          const SizedBox(height: 8),
          SWCard(
            child: Column(
              children: [
                _buildThaliPortion('50% Vegetables & Salad', 'Green leafy veggies, cucumber, tomatoes, cooked sabzi (भाजी)', const Color(0xFF16A34A), Icons.eco),
                const Divider(height: 16),
                _buildThaliPortion('25% Proteins', 'Dal, sprouted moong (उसळ), paneer, curd, or eggs', const Color(0xFFD97706), Icons.egg),
                const Divider(height: 16),
                _buildThaliPortion('25% Complex Grains', 'Jowar / Bajra / Wheat roti or hand-pounded brown rice', const Color(0xFF0284C7), Icons.bakery_dining),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. Nutritional Category Cards
          Text(
            AppTranslations.tr(lang, 'healthyDietTips'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildFoodCard('Whole Grains', 'Jowar, Bajra & Ragi', Icons.grass, const Color(0xFFD97706)),
              _buildFoodCard('Lean Proteins', 'Moong Dal, Sprouted Usal, Eggs', Icons.egg, const Color(0xFFBA1A1A)),
              _buildFoodCard('Dairy & Probiotics', 'Homemade Curd (दही) & Chaas', Icons.icecream, const Color(0xFF0284C7)),
              _buildFoodCard('Vitamins & Fiber', 'Seasonal Sabzi, Amla, Spinach', Icons.apple, const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDietAlert({
    required String title,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required List<String> tips,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThaliPortion(String title, String desc, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(String title, String subtitle, IconData icon, Color color) {
    return SWCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
