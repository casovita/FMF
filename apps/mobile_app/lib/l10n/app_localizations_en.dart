// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness Monster Factory';

  @override
  String get homeWelcomeTitle => 'Your Skills Academy';

  @override
  String get homeWelcomeSubtitle => 'Choose a skill to begin your progression.';

  @override
  String get skillHandstandTitle => 'Handstand';

  @override
  String get skillHandstandDescription =>
      'Build balance, body tension, and overhead strength.';

  @override
  String get skillPullupsTitle => 'Pull-ups';

  @override
  String get skillPullupsDescription =>
      'Develop pulling strength from dead hang to weighted.';

  @override
  String get skillHandstandPushupsTitle => 'Handstand Push-ups';

  @override
  String get skillHandstandPushupsDescription =>
      'Progress from pike press to freestanding HSPU.';

  @override
  String get progressTitle => 'Your Progress';

  @override
  String get practiceSessionTitle => 'Practice Session';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get emptyStateNoSessions =>
      'No practice sessions yet. Start training!';
}
