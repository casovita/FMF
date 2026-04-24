# Skill: scaffold-feature

Scaffold a new FMF feature module with the correct layer structure.

## Usage

```
/scaffold-feature <feature_name>
```

Example: `/scaffold-feature skill_planche`

## What Gets Created

```
apps/mobile_app/lib/features/<feature_name>/
  presentation/screens/<feature_name>_screen.dart
  application/<feature_name>_provider.dart
```

Plus:
- Route entry added to `apps/mobile_app/lib/app/router.dart`
- Placeholder test in `apps/mobile_app/test/unit/<feature_name>_test.dart`

## Screen Template

```dart
class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(featureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('...')),
      body: dataAsync.when(
        data: (data) => ...,
        loading: () => const FmfLoadingIndicator(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

## Provider Template

```dart
@riverpod
Future<FeatureData> feature(Ref ref) async {
  // TODO: inject repository via ref.watch(...)
  return FeatureData(...);
}
```

## Academy Naming Rules

- "module" not "page"
- "track" not "level"
- "practice" not "workout"
- "progression" not "progress bar"
- "curriculum" not "program"
