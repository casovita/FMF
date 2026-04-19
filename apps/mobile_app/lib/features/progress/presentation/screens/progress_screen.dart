import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmf_design_system/design_system.dart';
import 'package:mobile_app/features/progress/application/progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentPracticeSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: sessionsAsync.when(
        data: (sessions) => sessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(FmfSpacing.lg),
                  child: Text(
                    'No practice sessions yet. Start training!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(FmfSpacing.md),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: FmfSpacing.xs,
                      horizontal: 0,
                    ),
                    title: Text(
                      s.skillId,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      s.date.toLocal().toString().split(' ')[0],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '${s.durationMinutes} min',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading progress: $err')),
      ),
    );
  }
}
