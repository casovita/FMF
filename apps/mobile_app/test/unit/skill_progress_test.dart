import 'package:flutter_test/flutter_test.dart';
import 'package:fmf_domain/domain.dart';

void main() {
  group('PracticeSession', () {
    test('creates a valid session with required fields', () {
      final session = PracticeSession(
        id: 'test-001',
        skillId: 'handstand',
        date: DateTime(2026, 4, 1),
        durationMinutes: 20,
      );

      expect(session.id, 'test-001');
      expect(session.skillId, 'handstand');
      expect(session.durationMinutes, 20);
      expect(session.notes, isNull);
    });

    test('two sessions with identical values are equal (freezed)', () {
      final date = DateTime(2026, 4, 1);
      final a = PracticeSession(id: 'id', skillId: 'handstand', date: date, durationMinutes: 15);
      final b = PracticeSession(id: 'id', skillId: 'handstand', date: date, durationMinutes: 15);

      expect(a, equals(b));
    });

    test('copyWith updates only specified fields', () {
      final session = PracticeSession(
        id: 'id',
        skillId: 'handstand',
        date: DateTime(2026, 4, 1),
        durationMinutes: 15,
      );

      final updated = session.copyWith(durationMinutes: 30);

      expect(updated.durationMinutes, 30);
      expect(updated.skillId, 'handstand');
      expect(updated.id, 'id');
    });
  });

  group('ProgressSnapshot', () {
    test('creates snapshot with required fields', () {
      final snapshot = ProgressSnapshot(
        id: 'snap-001',
        skillId: 'pullups',
        snapshotDate: DateTime(2026, 4, 1),
        practiceCount: 5,
      );

      expect(snapshot.practiceCount, 5);
      expect(snapshot.trackId, isNull);
    });
  });
}
