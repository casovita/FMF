import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/features/skill_handstand/application/skill_handstand_provider.dart';

part 'skill_pullups_provider.g.dart';

@riverpod
Future<SkillDetail> skillPullups(Ref ref) async {
  // TODO: Inject SkillRepository via ref.watch(skillRepositoryProvider)
  return const SkillDetail(
    id: 'pullups',
    name: 'Pull-ups',
    description:
        'Pull-ups build essential pulling strength from a dead hang. '
        'Progress through negatives, assisted reps, strict pull-ups, '
        'and eventually weighted variations.',
  );
}
