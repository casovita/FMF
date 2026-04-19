import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fmf_data/data.dart';
import 'package:fmf_domain/domain.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
SkillRepository skillRepository(Ref ref) {
  return LocalSkillRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
PracticeSessionRepository practiceSessionRepository(Ref ref) {
  return LocalPracticeSessionRepository(ref.watch(appDatabaseProvider));
}
