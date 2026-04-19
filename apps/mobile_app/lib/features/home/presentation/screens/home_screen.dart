import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fmf_design_system/design_system.dart';
import 'package:mobile_app/features/home/application/home_provider.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final modulesAsync = ref.watch(academyModulesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(l10n.homeWelcomeTitle),
              centerTitle: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: FmfSpacing.md,
                vertical: FmfSpacing.xs,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.homeWelcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(top: FmfSpacing.md),
            ),
            modulesAsync.when(
              data: (modules) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: FmfSpacing.md),
                sliver: SliverList.separated(
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: FmfSpacing.sm),
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return _SkillModuleCard(
                      title: module.title,
                      description: module.description,
                      onTap: () => context.go(module.route),
                    );
                  },
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading curriculum: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillModuleCard extends StatelessWidget {
  const _SkillModuleCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FmfRadius.lg),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(FmfRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(FmfSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: FmfSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FmfSpacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
