import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_handstand_provider.g.dart';

class SkillDetail {
  const SkillDetail({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

@riverpod
Future<SkillDetail> skillHandstand(Ref ref) async {
  // TODO: Inject SkillRepository via ref.watch(skillRepositoryProvider) and load from Drift
  return const SkillDetail(
    id: 'handstand',
    name: 'Handstand',
    description:
        'The handstand is a fundamental gymnastics skill that builds balance, '
        'body tension, and overhead strength. Master the wall handstand before '
        'progressing to freestanding balance.',
  );
}
