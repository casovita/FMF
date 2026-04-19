import 'package:fmf_domain/domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/shared/providers/database_provider.dart';

part 'progress_provider.g.dart';

@riverpod
Future<List<PracticeSession>> recentPracticeSessions(Ref ref) async {
  final repo = ref.watch(practiceSessionRepositoryProvider);
  return repo.getRecentSessions(limit: 10);
}
