import 'package:mobile_app/features/skill_handstand/application/skill_handstand_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_handstand_pushups_provider.g.dart';

@riverpod
Future<SkillDetail> skillHandstandPushups(Ref ref) async {
  // TODO: Inject SkillRepository via ref.watch(skillRepositoryProvider)
  return const SkillDetail(
    id: 'handstand_pushups',
    name: 'Handstand Push-ups',
    description:
        'Handstand push-ups combine overhead pressing strength with '
        'handstand balance. Begin with pike push-ups, progress to wall HSPU, '
        'and work toward freestanding handstand push-ups.',
  );
}
