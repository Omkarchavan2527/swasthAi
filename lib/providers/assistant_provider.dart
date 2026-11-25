import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AssistantMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isRag;

  AssistantMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isRag = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isRag': isRag,
      };

  factory AssistantMessage.fromMap(Map<String, dynamic> map) => AssistantMessage(
        text: map['text'] ?? '',
        isUser: map['isUser'] ?? false,
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        isRag: map['isRag'] ?? false,
      );
}

final assistantMessagesProvider =
    StateNotifierProvider<AssistantMessagesNotifier, List<AssistantMessage>>((ref) {
  return AssistantMessagesNotifier();
});

class AssistantMessagesNotifier extends StateNotifier<List<AssistantMessage>> {
  static const String _storageKey = 'assistant_chat_history_v2';

  AssistantMessagesNotifier() : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final box = Hive.box('settings');
      final raw = box.get(_storageKey);
      if (raw != null && raw is List) {
        state = raw
            .map((e) => AssistantMessage.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
  }

  void addMessage(AssistantMessage msg) {
    state = [...state, msg];
    _persist();
  }

  void setInitialWelcome(String welcomeText) {
    if (state.isEmpty) {
      state = [
        AssistantMessage(
          text: welcomeText,
          isUser: false,
          isRag: false,
        )
      ];
      _persist();
    }
  }

  void updateFirstWelcomeIfOnly(String welcomeText) {
    if (state.length == 1 && !state.first.isUser) {
      state = [
        AssistantMessage(
          text: welcomeText,
          isUser: false,
          isRag: false,
        )
      ];
      _persist();
    }
  }

  void clearChat(String welcomeText) {
    state = [
      AssistantMessage(
        text: welcomeText,
        isUser: false,
        isRag: false,
      )
    ];
    _persist();
  }

  void _persist() {
    try {
      final box = Hive.box('settings');
      final list = state.map((m) => m.toMap()).toList();
      box.put(_storageKey, list);
    } catch (_) {}
  }
}
