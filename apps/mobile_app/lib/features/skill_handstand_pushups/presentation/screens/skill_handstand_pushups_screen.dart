import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmf_design_system/design_system.dart';
import 'package:mobile_app/core/widgets/loading_indicator.dart';
import 'package:mobile_app/features/skill_handstand/application/skill_handstand_provider.dart';
import 'package:mobile_app/features/skill_handstand_pushups/application/skill_handstand_pushups_provider.dart';

class SkillHandstandPushupsScreen extends ConsumerWidget {
  const SkillHandstandPushupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillAsync = ref.watch(skillHandstandPushupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Handstand Push-ups')),
      body: skillAsync.when(
        data: (skill) => _SkillContent(skill: skill),
        loading: () => const FmfLoadingIndicator(),
        error: (err, _) => Center(child: Text('Error loading module: $err')),
      ),
    );
  }
}

class _SkillContent extends StatelessWidget {
  const _SkillContent({required this.skill});

  final SkillDetail skill;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(FmfSpacing.md),
      children: [
        Text(skill.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: FmfSpacing.sm),
        Text(skill.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: FmfSpacing.lg),
        Text(
          'Progression tracks coming in next iteration.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
