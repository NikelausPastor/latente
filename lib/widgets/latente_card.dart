import 'package:flutter/material.dart';

class LatenteCard extends StatelessWidget {
  const LatenteCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
