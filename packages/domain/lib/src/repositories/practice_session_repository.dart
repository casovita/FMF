import 'package:fmf_domain/src/models/practice_session.dart';

abstract interface class PracticeSessionRepository {
  Future<void> logSession(PracticeSession session);
  Future<List<PracticeSession>> getSessionsForSkill(String skillId);
  Future<List<PracticeSession>> getRecentSessions({int limit = 10});
}
