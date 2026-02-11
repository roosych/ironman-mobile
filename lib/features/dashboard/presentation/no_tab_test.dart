import 'package:flutter/material.dart';

/// ТЕСТ БЕЗ TAB CONTROLLER
/// Полностью изолированный экран для проверки TabController конфликтов
class NoTabTest extends StatelessWidget {
  final int athleteId;

  const NoTabTest({
    super.key,
    required this.athleteId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('No Tab Test - Athlete $athleteId'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              'БЕЗ TabController',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Если этот экран работает,\nто проблема в TabBarView!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}