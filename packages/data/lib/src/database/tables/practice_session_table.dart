import 'package:drift/drift.dart';

class PracticeSessionTable extends Table {
  @override
  String get tableName => 'practice_sessions';

  TextColumn get id => text()();
  TextColumn get skillId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get durationMinutes => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
