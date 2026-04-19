import 'package:drift/drift.dart';
import 'package:fmf_data/src/database/app_database.dart';
import 'package:fmf_domain/domain.dart';

class LocalSkillRepository implements SkillRepository {
  const LocalSkillRepository(this._db);

  final AppDatabase _db;

  // Static skill catalog — in future, load from remote CMS or local JSON bundle
  static const _skills = [
    Skill(
      id: 'handstand',
      name: 'Handstand',
      description: 'Build balance, body tension, and overhead strength.',
      category: SkillCategory.balance,
    ),
    Skill(
      id: 'pullups',
      name: 'Pull-ups',
      description: 'Develop pulling strength from dead hang to weighted.',
      category: SkillCategory.strength,
    ),
    Skill(
      id: 'handstand_pushups',
      name: 'Handstand Push-ups',
      description: 'Progress from pike press to freestanding HSPU.',
      category: SkillCategory.strength,
    ),
  ];

  @override
  Future<List<Skill>> getSkills() async => _skills;

  @override
  Future<Skill?> getSkillById(String id) async {
    return _skills.where((s) => s.id == id).firstOrNull;
  }

  @override
  Stream<ProgressSnapshot?> watchSkillProgress(String skillId) {
    return (_db.select(_db.skillProgressTable)
          ..where((t) => t.skillId.equals(skillId))
          ..orderBy([(t) => OrderingTerm.desc(t.snapshotDate)])
          ..limit(1))
        .watchSingleOrNull()
        .map(
          (row) => row == null
              ? null
              : ProgressSnapshot(
                  id: row.id,
                  skillId: row.skillId,
                  trackId: row.trackId,
                  snapshotDate: row.snapshotDate,
                  practiceCount: row.practiceCount,
                  lastPracticeDate: row.lastPracticeDate,
                ),
        );
  }
}
