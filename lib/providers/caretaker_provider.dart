import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cloud_sync_service.dart';
import 'family_provider.dart';

final caretakerDashboardProvider = StateNotifierProvider<CaretakerDashboardNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final activeMember = ref.watch(activeMemberProvider);
  return CaretakerDashboardNotifier(ref, activeMember?.id);
});

class CaretakerDashboardNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref ref;
  final String? caretakerProfileId;

  CaretakerDashboardNotifier(this.ref, this.caretakerProfileId) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (caretakerProfileId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final cloudService = ref.read(cloudSyncServiceProvider);
      final data = await cloudService.fetchCaretakerDashboard(caretakerProfileId!);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
