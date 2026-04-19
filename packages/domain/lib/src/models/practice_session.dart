import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_session.freezed.dart';
part 'practice_session.g.dart';

@freezed
class PracticeSession with _$PracticeSession {
  const factory PracticeSession({
    required String id,
    required String skillId,
    required DateTime date,
    required int durationMinutes,
    String? notes,
    DateTime? completedAt,
  }) = _PracticeSession;

  factory PracticeSession.fromJson(Map<String, dynamic> json) => _$PracticeSessionFromJson(json);
}
