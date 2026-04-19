import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill.freezed.dart';
part 'skill.g.dart';

enum SkillCategory { balance, strength, bodyweight }

@freezed
class Skill with _$Skill {
  const factory Skill({
    required String id,
    required String name,
    required String description,
    required SkillCategory category,
  }) = _Skill;

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
}
