import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'practice_session_provider.g.dart';

@riverpod
class PracticeSessionController extends _$PracticeSessionController {
  @override
  Future<void> build() async {}

  Future<void> logSession({
    required String skillId,
    required int durationMinutes,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    // TODO: Inject PracticeSessionRepository and call repo.logSession(...)
    await Future<void>.delayed(const Duration(milliseconds: 200));
    state = const AsyncValue.data(null);
  }
}
