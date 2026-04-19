import 'package:mobile_app/app/bootstrap/bootstrap.dart';
import 'package:mobile_app/app/flavor/app_flavor.dart';

void main() => bootstrap(
      const FlavorConfig(
        flavor: AppFlavor.prod,
        appName: 'Fitness Monster Factory',
        envLabel: 'prod',
      ),
    );
