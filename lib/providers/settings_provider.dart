import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsBoxProvider = Provider<Box>((ref) => Hive.box('settings'));

final languageProvider = StateNotifierProvider<SettingsNotifier<String>, String>((ref) {
  return SettingsNotifier<String>(ref.watch(settingsBoxProvider), 'language', 'en');
});

final elderlyModeProvider = StateNotifierProvider<SettingsNotifier<bool>, bool>((ref) {
  return SettingsNotifier<bool>(ref.watch(settingsBoxProvider), 'elderlyMode', false);
});

final lowLiteracyModeProvider = StateNotifierProvider<SettingsNotifier<bool>, bool>((ref) {
  return SettingsNotifier<bool>(ref.watch(settingsBoxProvider), 'lowLiteracyMode', false);
});

final aiApiKeyProvider = StateNotifierProvider<SettingsNotifier<String>, String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final saved = box.get('openrouterApiKey') ?? box.get('aiApiKey') ?? box.get('geminiApiKey') ?? '';
  return SettingsNotifier<String>(box, 'openrouterApiKey', saved.toString());
});

final geminiApiKeyProvider = aiApiKeyProvider;

final openrouterModelProvider = StateNotifierProvider<SettingsNotifier<String>, String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  var saved = box.get('openrouterModel', defaultValue: 'google/gemini-2.0-flash-001')?.toString() ?? 'google/gemini-2.0-flash-001';
  if (saved.contains('2.5') || saved.contains('3.5')) {
    saved = 'google/gemini-2.0-flash-001';
  }
  return SettingsNotifier<String>(box, 'openrouterModel', saved);
});

class SettingsNotifier<T> extends StateNotifier<T> {
  final Box box;
  final String key;
  final T defaultValue;

  SettingsNotifier(this.box, this.key, this.defaultValue) : super(_load(box, key, defaultValue));

  static T _load<T>(Box box, String key, T defaultValue) {
    return box.get(key, defaultValue: defaultValue) as T;
  }

  void updateValue(T value) {
    box.put(key, value);
    state = value;
  }
}
