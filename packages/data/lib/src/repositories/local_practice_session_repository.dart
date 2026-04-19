import 'package:drift/drift.dart';
import 'package:fmf_data/src/database/app_database.dart';
import 'package:fmf_domain/domain.dart';

class LocalPracticeSessionRepository implements PracticeSessionRepository {
  const LocalPracticeSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> logSession(PracticeSession session) async {
    await _db.into(_db.practiceSessionTable).insertOnConflictUpdate(
          PracticeSessionTableCompanion.insert(
            id: session.id,
            skillId: session.skillId,
            date: session.date,
            durationMinutes: session.durationMinutes,
            notes: Value(session.notes),
            completedAt: Value(session.completedAt),
          ),
        );
  }

  @override
  Future<List<PracticeSession>> getSessionsForSkill(String skillId) async {
    final rows = await (_db.select(_db.practiceSessionTable)
          ..where((t) => t.skillId.equals(skillId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<List<PracticeSession>> getRecentSessions({int limit = 10}) async {
    final rows = await (_db.select(_db.practiceSessionTable)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
    return rows.map(_rowToModel).toList();
  }

  PracticeSession _rowToModel(PracticeSessionTableData row) => PracticeSession(
        id: row.id,
        skillId: row.skillId,
        date: row.date,
        durationMinutes: row.durationMinutes,
        notes: row.notes,
        completedAt: row.completedAt,
      );
}
