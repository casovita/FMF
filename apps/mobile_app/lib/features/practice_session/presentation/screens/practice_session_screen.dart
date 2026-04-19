import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmf_design_system/design_system.dart';
import 'package:mobile_app/features/practice_session/application/practice_session_provider.dart';

class PracticeSessionScreen extends ConsumerWidget {
  const PracticeSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Session')),
      body: Padding(
        padding: const EdgeInsets.all(FmfSpacing.md),
        child: state.when(
          data: (_) => const _PracticeSessionForm(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _PracticeSessionForm extends StatelessWidget {
  const _PracticeSessionForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log a Practice Session', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: FmfSpacing.md),
        Text(
          'Session logging form coming in next iteration.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        // TODO: Add skill selector dropdown
        // TODO: Add duration input
        // TODO: Add optional notes field
        // TODO: Add submit button that calls PracticeSessionController.logSession()
      ],
    );
  }
}
