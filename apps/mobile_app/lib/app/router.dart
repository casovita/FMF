import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/home/presentation/screens/home_screen.dart';
import 'package:mobile_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mobile_app/features/practice_session/presentation/screens/practice_session_screen.dart';
import 'package:mobile_app/features/progress/presentation/screens/progress_screen.dart';
import 'package:mobile_app/features/skill_handstand/presentation/screens/skill_handstand_screen.dart';
import 'package:mobile_app/features/skill_handstand_pushups/presentation/screens/skill_handstand_pushups_screen.dart';
import 'package:mobile_app/features/skill_pullups/presentation/screens/skill_pullups_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const skillHandstand = '/skill/handstand';
  static const skillPullups = '/skill/pullups';
  static const skillHandstandPushups = '/skill/handstand-pushups';
  static const practiceSession = '/practice';
  static const progress = '/progress';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  // TODO: Add auth redirect guard here when auth is implemented:
  // redirect: (context, state) => authGuard(ref, state),
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillHandstand,
      name: 'skill-handstand',
      builder: (context, state) => const SkillHandstandScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillPullups,
      name: 'skill-pullups',
      builder: (context, state) => const SkillPullupsScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillHandstandPushups,
      name: 'skill-handstand-pushups',
      builder: (context, state) => const SkillHandstandPushupsScreen(),
    ),
    GoRoute(
      path: AppRoutes.practiceSession,
      name: 'practice-session',
      builder: (context, state) => const PracticeSessionScreen(),
    ),
    GoRoute(
      path: AppRoutes.progress,
      name: 'progress',
      builder: (context, state) => const ProgressScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
