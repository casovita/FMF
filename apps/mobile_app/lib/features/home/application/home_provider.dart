import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/app/router.dart';

part 'home_provider.g.dart';

class AcademyModuleEntry {
  const AcademyModuleEntry({
    required this.skillId,
    required this.title,
    required this.description,
    required this.route,
  });

  final String skillId;
  final String title;
  final String description;
  final String route;
}

@riverpod
Future<List<AcademyModuleEntry>> academyModules(Ref ref) async {
  // TODO: In future, load from SkillRepository + merge with user progress data
  return [
    const AcademyModuleEntry(
      skillId: 'handstand',
      title: 'Handstand',
      description: 'Build balance, body tension, and overhead strength.',
      route: AppRoutes.skillHandstand,
    ),
    const AcademyModuleEntry(
      skillId: 'pullups',
      title: 'Pull-ups',
      description: 'Develop pulling strength from dead hang to weighted.',
      route: AppRoutes.skillPullups,
    ),
    const AcademyModuleEntry(
      skillId: 'handstand_pushups',
      title: 'Handstand Push-ups',
      description: 'Progress from pike press to freestanding HSPU.',
      route: AppRoutes.skillHandstandPushups,
    ),
  ];
}
