import 'package:drift/drift.dart';

class SkillProgressTable extends Table {
  @override
  String get tableName => 'skill_progress';

  TextColumn get id => text()();
  TextColumn get skillId => text()();
  TextColumn get trackId => text().nullable()();
  DateTimeColumn get snapshotDate => dateTime()();
  IntColumn get practiceCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticeDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
