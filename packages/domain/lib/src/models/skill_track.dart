import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_track.freezed.dart';
part 'skill_track.g.dart';

@freezed
abstract class SkillTrack with _$SkillTrack {
  const factory SkillTrack({
    required String id,
    required String skillId,
    required String name,
    required int order,
    required String description,
    required int requiredPracticeCount,
  }) = _SkillTrack;

  factory SkillTrack.fromJson(Map<String, dynamic> json) => _$SkillTrackFromJson(json);
}
