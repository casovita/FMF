import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:fmf_data/src/database/tables/practice_session_table.dart';
import 'package:fmf_data/src/database/tables/skill_progress_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SkillProgressTable, PracticeSessionTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _defaultConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _defaultConnection() {
    return driftDatabase(name: 'fmf_database');
  }
}
