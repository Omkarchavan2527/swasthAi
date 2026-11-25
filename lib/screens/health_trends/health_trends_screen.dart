import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/i18n/app_translations.dart';
import '../../data/models/health_measurement.dart';
import '../../providers/family_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/member_switcher.dart';

final measurementsProvider =
    StateNotifierProvider<MeasurementsNotifier, List<HealthMeasurement>>((ref) {
  return MeasurementsNotifier();
});

class MeasurementsNotifier extends StateNotifier<List<HealthMeasurement>> {
  MeasurementsNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<HealthMeasurement>('measurements');
    if (box.isEmpty) {
      final m1 = HealthMeasurement()
        ..id = 'hm1'
        ..memberId = '1'
        ..memberName = 'Rajesh Patil'
        ..date = '2024-05-01'
        ..systolicBP = 120
        ..diastolicBP = 80
        ..bloodSugar = 95.0
        ..weight = 72.0
        ..heartRate = 72;

      final m2 = HealthMeasurement()
        ..id = 'hm2'
        ..memberId = '1'
        ..memberName = 'Rajesh Patil'
        ..date = '2024-05-10'
        ..systolicBP = 124
        ..diastolicBP = 82
        ..bloodSugar = 98.0
        ..weight = 71.8
        ..heartRate = 75;

      final m3 = HealthMeasurement()
        ..id = 'hm3'
        ..memberId = '1'
        ..memberName = 'Rajesh Patil'
        ..date = '2024-05-20'
        ..systolicBP = 118
        ..diastolicBP = 78
        ..bloodSugar = 92.0
        ..weight = 71.5
        ..heartRate = 70;

      box.putAll({m1.id: m1, m2.id: m2, m3.id: m3});
    }
    state = box.values.toList();
  }

  void addMeasurement(HealthMeasurement m) {
    final box = Hive.box<HealthMeasurement>('measurements');
    box.put(m.id, m);
    box.flush();
    state = box.values.toList();
  }
}

class HealthTrendsScreen extends ConsumerStatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  ConsumerState<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends ConsumerState<HealthTrendsScreen> {
  String _selectedTimeframe = '30 Days';
  String _selectedMetric = 'BP'; // 'BP', 'Sugar', 'HeartRate', 'Weight'

  void _showAddReadingDialog(BuildContext context) {
    final sysController = TextEditingController(text: '120');
    final diaController = TextEditingController(text: '80');
    final sugarController = TextEditingController(text: '95');
    final heartRateController = TextEditingController(text: '72');
    final weightController = TextEditingController(text: '70');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              const Row(
                children: [
                  Icon(Icons.monitor_heart, color: Color(0xFF00685F), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Log Clinical Measurement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF121C2A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Record daily vitals conforming to ICMR health standards',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // BP Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Systolic BP (mmHg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: sysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '120',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diastolic BP (mmHg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: diaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '80',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sugar & Heart Rate
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Blood Sugar (mg/dL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: sugarController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '95',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Heart Rate (bpm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: heartRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '72',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weight
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Body Weight (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '70',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      isDense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00685F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Save Reading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    final activeMember = ref.read(activeMemberProvider);
                    final m = HealthMeasurement()
                      ..id = const Uuid().v4()
                      ..memberId = activeMember?.id ?? '1'
                      ..memberName = activeMember?.name ?? 'Patient'
                      ..date = DateTime.now().toString().substring(0, 10)
                      ..systolicBP = int.tryParse(sysController.text) ?? 120
                      ..diastolicBP = int.tryParse(diaController.text) ?? 80
                      ..bloodSugar = double.tryParse(sugarController.text) ?? 95.0
                      ..weight = double.tryParse(weightController.text) ?? 70.0
                      ..heartRate = int.tryParse(heartRateController.text) ?? 72;

                    ref.read(measurementsProvider.notifier).addMeasurement(m);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vitals reading saved to health vault!')),
                    );
                  },
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
    final activeMember = ref.watch(activeMemberProvider);
    final allMeasurements = ref.watch(measurementsProvider);
    final memberMeasurements = allMeasurements
        .where((m) => m.memberId == (activeMember?.id ?? '1'))
        .toList();
    final latest =
        memberMeasurements.isNotEmpty ? memberMeasurements.last : null;

    // Build chart spots based on selected metric
    List<FlSpot> spots = [];
    String metricTitle = 'Systolic Blood Pressure';
    String metricUnit = 'mmHg';
    String targetText = 'ICMR Target: < 120 mmHg';

    if (_selectedMetric == 'BP') {
      metricTitle = 'Systolic Blood Pressure';
      metricUnit = 'mmHg';
      targetText = 'Normal: 90 - 120 mmHg';
      spots = memberMeasurements.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.systolicBP.toDouble());
      }).toList();
      if (spots.isEmpty) spots = const [FlSpot(0, 120), FlSpot(1, 124), FlSpot(2, 118)];
    } else if (_selectedMetric == 'Sugar') {
      metricTitle = 'Fasting Blood Glucose';
      metricUnit = 'mg/dL';
      targetText = 'Target: 70 - 100 mg/dL';
      spots = memberMeasurements.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.bloodSugar);
      }).toList();
      if (spots.isEmpty) spots = const [FlSpot(0, 95), FlSpot(1, 98), FlSpot(2, 92)];
    } else if (_selectedMetric == 'HeartRate') {
      metricTitle = 'Resting Heart Rate';
      metricUnit = 'bpm';
      targetText = 'Resting Normal: 60 - 100 bpm';
      spots = memberMeasurements.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.heartRate.toDouble());
      }).toList();
      if (spots.isEmpty) spots = const [FlSpot(0, 72), FlSpot(1, 75), FlSpot(2, 70)];
    } else {
      metricTitle = 'Body Weight';
      metricUnit = 'kg';
      targetText = 'Target: Consistent BMI';
      spots = memberMeasurements.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.weight);
      }).toList();
      if (spots.isEmpty) spots = const [FlSpot(0, 72), FlSpot(1, 71.8), FlSpot(2, 71.5)];
    }

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
                  AppTranslations.tr(lang, 'trendsTitle'),
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
                  child: Text(AppTranslations.tr(lang, 'active'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                ),
              ],
            ),
            Text(
              AppTranslations.tr(lang, 'vitalsTitle'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF00685F), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating clinical vitals summary PDF...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Member Switcher Carousel
          const MemberSwitcher(),

          // Main scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // Timeframe Selector Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['7 Days', '30 Days', '3 Months', '1 Year'].map((tf) {
                      final isSel = _selectedTimeframe == tf;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTimeframe = tf),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSel
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 3)]
                                  : null,
                            ),
                            child: Text(
                              tf,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF00685F) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Metric Pills Horizontal Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMetricPill(
                        'BP',
                        'Blood Pressure',
                        latest != null ? '${latest.systolicBP}/${latest.diastolicBP}' : '120/80',
                        'mmHg',
                        Icons.favorite,
                        const Color(0xFF00685F),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricPill(
                        'Sugar',
                        'Fasting Sugar',
                        latest != null ? '${latest.bloodSugar}' : '95',
                        'mg/dL',
                        Icons.water_drop,
                        const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricPill(
                        'HeartRate',
                        'Heart Rate',
                        latest != null ? '${latest.heartRate}' : '72',
                        'bpm',
                        Icons.monitor_heart,
                        const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricPill(
                        'Weight',
                        'Weight',
                        latest != null ? '${latest.weight}' : '70',
                        'kg',
                        Icons.scale,
                        const Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Clinical Trend Graph Card
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$metricTitle ($metricUnit)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121C2A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetText,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF00685F), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Color(0xFF00685F)),
                                SizedBox(width: 4),
                                Text('In Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00685F))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Color(0xFFF1F5F9),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: const FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: const Color(0xFF00685F),
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF00685F).withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recent Readings Log Section
                const Text(
                  'Recorded Clinical History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                ),
                const SizedBox(height: 10),

                if (memberMeasurements.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('No vitals logged yet. Tap "Log Reading" below.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ),
                  )
                else
                  ...memberMeasurements.reversed.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long, color: Color(0xFF00685F), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BP: ${m.systolicBP}/${m.diastolicBP} mmHg • Sugar: ${m.bloodSugar.toStringAsFixed(0)} mg/dL',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF121C2A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: ${m.date} • HR: ${m.heartRate} bpm • Weight: ${m.weight} kg',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(AppTranslations.tr(lang, 'verified'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006F67))),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00685F),
        onPressed: () => _showAddReadingDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppTranslations.tr(lang, 'addReading'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMetricPill(String id, String label, String value, String unit, IconData icon, Color color) {
    final isSel = _selectedMetric == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetric = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00685F) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? const Color(0xFF00685F) : const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x040F172A), blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSel ? const Color(0xFFCCFBF1) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '$value $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSel ? Colors.white : const Color(0xFF121C2A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
