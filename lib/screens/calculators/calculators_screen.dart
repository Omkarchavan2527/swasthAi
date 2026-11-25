import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sw_card.dart';

class CalculatorsScreen extends ConsumerWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.tr(lang, 'calculatorsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        children: [
          _buildCalcCard(
            title: AppTranslations.tr(lang, 'bmiCalculator'),
            subtitle: 'Body Mass Index & Weight',
            icon: Icons.monitor_weight_outlined,
            color: const Color(0xFF00685F),
            onTap: () => _openBmiCalculator(context),
          ),
          _buildCalcCard(
            title: AppTranslations.tr(lang, 'dailyCalories'),
            subtitle: 'BMR & Maintenance TDEE',
            icon: Icons.local_fire_department,
            color: const Color(0xFFD97706),
            onTap: () => _openCalorieCalculator(context),
          ),
          _buildCalcCard(
            title: 'Pregnancy Due Date',
            subtitle: 'EDD & Gestational Age',
            icon: Icons.child_care,
            color: const Color(0xFFEC4899),
            onTap: () => _openPregnancyCalculator(context),
          ),
          _buildCalcCard(
            title: 'Cycle & Ovulation',
            subtitle: 'Fertile Window Tracker',
            icon: Icons.calendar_month,
            color: const Color(0xFF8B5CF6),
            onTap: () => _openCycleCalculator(context),
          ),
          _buildCalcCard(
            title: 'BP Category Interpreter',
            subtitle: 'Systolic / Diastolic Check',
            icon: Icons.favorite,
            color: const Color(0xFFBA1A1A),
            onTap: () => _openBpCalculator(context),
          ),
          _buildCalcCard(
            title: 'Water Hydration Goal',
            subtitle: 'Personalized Daily Liters',
            icon: Icons.water_drop,
            color: const Color(0xFF0284C7),
            onTap: () => _openWaterCalculator(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SWCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // 1. BMI CALCULATOR
  void _openBmiCalculator(BuildContext context) {
    final heightCtrl = TextEditingController(text: '170');
    final weightCtrl = TextEditingController(text: '70');
    double? bmiResult;
    String category = '';
    Color categoryColor = Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('BMI Calculator (Body Mass Index)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.height, color: Color(0xFF00685F)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF00685F)),
                      ),
                    ),
                  ),
                ],
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
                    final h = double.tryParse(heightCtrl.text);
                    final w = double.tryParse(weightCtrl.text);
                    if (h != null && w != null && h > 0) {
                      final meters = h / 100.0;
                      final bmi = w / (meters * meters);
                      String cat;
                      Color col;
                      if (bmi < 18.5) {
                        cat = 'Underweight';
                        col = Colors.orange;
                      } else if (bmi < 23.0) {
                        // Asian Indian BMI cutoffs
                        cat = 'Normal (Healthy Weight for Asian Indians)';
                        col = const Color(0xFF00685F);
                      } else if (bmi < 27.5) {
                        cat = 'Overweight';
                        col = Colors.amber.shade800;
                      } else {
                        cat = 'Obese';
                        col = Colors.red;
                      }
                      setSheetState(() {
                        bmiResult = bmi;
                        category = cat;
                        categoryColor = col;
                      });
                    }
                  },
                  child: const Text('Calculate BMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (bmiResult != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your BMI: ${bmiResult!.toStringAsFixed(1)} kg/m²',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: categoryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: categoryColor)),
                      const SizedBox(height: 6),
                      const Text(
                        'Based on Asian Indian WHO/ICMR clinical criteria (Healthy range: 18.5 - 22.9).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 2. DAILY CALORIE NEEDS
  void _openCalorieCalculator(BuildContext context) {
    final ageCtrl = TextEditingController(text: '30');
    final weightCtrl = TextEditingController(text: '70');
    final heightCtrl = TextEditingController(text: '170');
    String gender = 'Male';
    String activity = 'Moderate (3-5 days exercise)';
    double? tdee;
    double? bmr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('Daily Calorie Needs (TDEE / BMR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setSheetState(() => gender = val ?? 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age (years)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: activity,
                decoration: InputDecoration(
                  labelText: 'Activity Level',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  'Sedentary (Little or no exercise)',
                  'Light (1-3 days/week)',
                  'Moderate (3-5 days exercise)',
                  'Active (Hard exercise 6-7 days)',
                ].map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => setSheetState(() => activity = val ?? activity),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final age = double.tryParse(ageCtrl.text) ?? 30;
                    final w = double.tryParse(weightCtrl.text) ?? 70;
                    final h = double.tryParse(heightCtrl.text) ?? 170;

                    // Mifflin-St Jeor Equation
                    double calcBmr = (10 * w) + (6.25 * h) - (5 * age);
                    if (gender == 'Male') {
                      calcBmr += 5;
                    } else {
                      calcBmr -= 161;
                    }

                    double multiplier = 1.2;
                    if (activity.startsWith('Light')) multiplier = 1.375;
                    if (activity.startsWith('Moderate')) multiplier = 1.55;
                    if (activity.startsWith('Active')) multiplier = 1.725;

                    setSheetState(() {
                      bmr = calcBmr;
                      tdee = calcBmr * multiplier;
                    });
                  },
                  child: const Text('Calculate Calories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (tdee != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Base BMR', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                          Text('${bmr!.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        ],
                      ),
                      Container(width: 1, height: 36, color: const Color(0xFFFDE68A)),
                      Column(
                        children: [
                          const Text('Maintenance Daily', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                          Text('${tdee!.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 3. PREGNANCY DUE DATE
  void _openPregnancyCalculator(BuildContext context) {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 60));
    DateTime? edd;
    int? gestationalWeeks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('Pregnancy Due Date Calculator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Calculated via Naegele\'s Rule (+280 days from LMP)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Color(0xFFEC4899)),
                title: const Text('First Day of Last Period (LMP)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 15, color: Color(0xFF121C2A), fontWeight: FontWeight.w600)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 300)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Change Date', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final calcEdd = selectedDate.add(const Duration(days: 280));
                    final diffDays = DateTime.now().difference(selectedDate).inDays;
                    setSheetState(() {
                      edd = calcEdd;
                      gestationalWeeks = diffDays ~/ 7;
                    });
                  },
                  child: const Text('Calculate Due Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (edd != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: Column(
                    children: [
                      const Text('Estimated Date of Delivery (EDD)', style: TextStyle(fontSize: 12, color: Color(0xFF9D174D))),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(edd!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBE185D)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Gestation: $gestationalWeeks weeks pregnant',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF831843)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 4. CYCLE & OVULATION
  void _openCycleCalculator(BuildContext context) {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 10));
    final cycleDaysCtrl = TextEditingController(text: '28');
    DateTime? ovulationDate;
    String fertileWindow = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('Cycle & Ovulation Window Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.water_drop, color: Color(0xFF8B5CF6)),
                title: const Text('Last Period Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 60)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheetState(() => selectedDate = picked);
                  },
                  child: const Text('Change Date', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cycleDaysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Average Cycle Length (Days)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.repeat, color: Color(0xFF8B5CF6)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final cycleDays = int.tryParse(cycleDaysCtrl.text) ?? 28;
                    // Ovulation happens ~14 days before next period
                    final nextPeriod = selectedDate.add(Duration(days: cycleDays));
                    final ovDate = nextPeriod.subtract(const Duration(days: 14));
                    final fertileStart = ovDate.subtract(const Duration(days: 4));
                    final fertileEnd = ovDate.add(const Duration(days: 1));

                    setSheetState(() {
                      ovulationDate = ovDate;
                      fertileWindow = '${DateFormat("dd MMM").format(fertileStart)} - ${DateFormat("dd MMM").format(fertileEnd)}';
                    });
                  },
                  child: const Text('Calculate Fertile Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (ovulationDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Column(
                    children: [
                      Text('Approximate Ovulation Day: ${DateFormat("EEEE, dd MMMM").format(ovulationDate!)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      const SizedBox(height: 6),
                      Text('Peak Fertile Window: $fertileWindow',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5B21B6))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 5. BP INTERPRETER
  void _openBpCalculator(BuildContext context) {
    final sysCtrl = TextEditingController(text: '120');
    final diaCtrl = TextEditingController(text: '80');
    String bpStatus = '';
    Color bpColor = Colors.green;
    String advice = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('Blood Pressure Category Interpreter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Based on Indian & AHA Clinical Cardiology Guidelines', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Systolic (Top, mmHg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Diastolic (Bottom, mmHg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final sys = int.tryParse(sysCtrl.text) ?? 120;
                    final dia = int.tryParse(diaCtrl.text) ?? 80;

                    String stat;
                    Color col;
                    String adv;

                    if (sys > 180 || dia > 120) {
                      stat = 'HYPERTENSIVE CRISIS (Emergency)';
                      col = Colors.red.shade900;
                      adv = 'Immediate medical attention required! Dial 108 or go to emergency room if experiencing chest pain or vision blur.';
                    } else if (sys >= 140 || dia >= 90) {
                      stat = 'Stage 2 Hypertension';
                      col = Colors.red;
                      adv = 'Doctor consultation recommended for anti-hypertensive medication review and strict salt reduction.';
                    } else if (sys >= 130 || dia >= 80) {
                      stat = 'Stage 1 Hypertension';
                      col = Colors.orange.shade800;
                      adv = 'Lifestyle modification: low-sodium diet, regular aerobic exercise, and stress reduction.';
                    } else if (sys >= 120 && dia < 80) {
                      stat = 'Elevated Blood Pressure';
                      col = Colors.amber.shade800;
                      adv = 'Maintain healthy diet and monitor weekly to prevent transition to hypertension.';
                    } else if (sys < 90 || dia < 60) {
                      stat = 'Low Blood Pressure (Hypotension)';
                      col = Colors.blue;
                      adv = 'Drink ORS or salted lime water, stay hydrated, and consult doctor if experiencing dizziness.';
                    } else {
                      stat = 'Normal & Healthy Blood Pressure';
                      col = const Color(0xFF00685F);
                      adv = 'Optimal cardiovascular health! Continue balanced diet and physical activity.';
                    }

                    setSheetState(() {
                      bpStatus = stat;
                      bpColor = col;
                      advice = adv;
                    });
                  },
                  child: const Text('Interpret BP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (bpStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bpColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bpColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bpStatus, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: bpColor)),
                      const SizedBox(height: 6),
                      Text(advice, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 6. WATER HYDRATION CALCULATOR
  void _openWaterCalculator(BuildContext context) {
    final weightCtrl = TextEditingController(text: '70');
    final exerciseCtrl = TextEditingController(text: '30');
    double? liters;
    int? glasses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              const Text('Personalized Water Hydration Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Body Weight (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: exerciseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Daily Exercise (min)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final w = double.tryParse(weightCtrl.text) ?? 70;
                    final ex = double.tryParse(exerciseCtrl.text) ?? 30;

                    // Standard formula: 35ml per kg body weight + 350ml per 30 min exercise
                    final baseMl = (w * 35) + (ex / 30.0 * 350);
                    final calcLiters = baseMl / 1000.0;

                    setSheetState(() {
                      liters = calcLiters;
                      glasses = (baseMl / 250).round();
                    });
                  },
                  child: const Text('Calculate Water Need', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (liters != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${liters!.toStringAsFixed(1)} Liters per Day',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Equivalent to ~$glasses glasses (250 ml each)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Keeps kidneys flushed, prevents urinary tract infections (UTI), and stabilizes blood pressure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
