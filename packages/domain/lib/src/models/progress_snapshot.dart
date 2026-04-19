import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_snapshot.freezed.dart';
part 'progress_snapshot.g.dart';

@freezed
class ProgressSnapshot with _$ProgressSnapshot {
  const factory ProgressSnapshot({
    required String id,
    required String skillId,
    String? trackId,
    required DateTime snapshotDate,
    required int practiceCount,
    DateTime? lastPracticeDate,
  }) = _ProgressSnapshot;

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) => _$ProgressSnapshotFromJson(json);
}
