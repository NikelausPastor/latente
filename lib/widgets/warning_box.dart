import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WarningBox extends StatelessWidget {
  const WarningBox({
    required this.messages,
    super.key,
  });

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'Avvisi operativi',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message),
            ),
        ],
      ),
    );
  }
}
