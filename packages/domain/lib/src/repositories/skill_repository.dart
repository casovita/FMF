import 'package:fmf_domain/src/models/progress_snapshot.dart';
import 'package:fmf_domain/src/models/skill.dart';

abstract interface class SkillRepository {
  Future<List<Skill>> getSkills();
  Future<Skill?> getSkillById(String id);
  Stream<ProgressSnapshot?> watchSkillProgress(String skillId);
}
