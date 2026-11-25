import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swasthai/app.dart';
import 'package:swasthai/data/models/family_member.dart';
import 'package:swasthai/data/models/medicine.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FamilyMemberAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox('settings');
    await Hive.openBox<FamilyMember>('family');
    await Hive.openBox<Medicine>('medicines');
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('SwasthAI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SwasthAIApp()));
    expect(find.byType(SwasthAIApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
