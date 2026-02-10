import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Экран истории сохранённых вычислений калькулятора.
/// Пока только с AppBar.
class PaceCalculatorHistoryScreen extends StatelessWidget {
  const PaceCalculatorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Calculation history',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
