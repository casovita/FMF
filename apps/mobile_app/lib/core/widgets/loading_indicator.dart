import 'package:flutter/material.dart';

class FmfLoadingIndicator extends StatelessWidget {
  const FmfLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
