import 'package:flutter/material.dart';
import 'package:fmf_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app/router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FmfSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Fitness Monster Factory',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FmfSpacing.md),
              Text(
                'A skills academy for serious training.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Begin Training'),
              ),
              const SizedBox(height: FmfSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
