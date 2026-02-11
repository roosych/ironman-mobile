import 'package:flutter/material.dart';
import 'no_tab_test.dart';

/// УЛЬТРА-МИНИМАЛЬНЫЙ ТЕСТ
/// Только StatefulWidget без initState, без async, без addPostFrameCallback
class UltraMinimalTest extends StatefulWidget {
  final int athleteId;

  const UltraMinimalTest({
    super.key,
    required this.athleteId,
  });

  @override
  State<UltraMinimalTest> createState() => _UltraMinimalTestState();
}

class _UltraMinimalTestState extends State<UltraMinimalTest> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint('🔥 ULTRA MINIMAL: Building for athlete ${widget.athleteId}');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ultra Minimal Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Athlete ID: ${widget.athleteId}'),
          const SizedBox(height: 16),
          Text('Counter: $counter'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                counter++;
              });
            },
            child: const Text('Увеличить счетчик'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NoTabTest(athleteId: widget.athleteId),
                ),
              );
            },
            child: const Text('Тест БЕЗ TabController'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Если этот тест зависает - проблема в TabController!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}