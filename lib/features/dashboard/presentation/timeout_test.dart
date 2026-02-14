import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// ТЕСТ TIMEOUT'а
/// Проверяем, работает ли timeout правильно
class TimeoutTest extends StatefulWidget {
  final int athleteId;

  const TimeoutTest({
    super.key,
    required this.athleteId,
  });

  @override
  State<TimeoutTest> createState() => _TimeoutTestState();
}

class _TimeoutTestState extends State<TimeoutTest> {
  bool isLoading = false;
  String? result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Тест Timeout',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          if (!isLoading) ...[
            ElevatedButton(
              onPressed: () => _testTimeout(3),
              child: const Text('Тест 3 секунды timeout'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _testTimeout(1),
              child: const Text('Тест 1 секунда timeout'),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Тестируем timeout...'),
          ],

          const SizedBox(height: 32),

          if (result != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(result!),
            ),
        ],
      ),
    );
  }

  void _testTimeout(int seconds) async {
    setState(() {
      isLoading = true;
      result = null;
    });

    try {
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: seconds);
      dio.options.receiveTimeout = Duration(seconds: seconds);

      final stopwatch = Stopwatch()..start();

      final response = await dio.get(
        'http://192.168.0.116:8000/api/v1/athletes/${widget.athleteId}/photos?page=1',
      );

      stopwatch.stop();

      setState(() {
        isLoading = false;
        result = '✅ Ответ получен за ${stopwatch.elapsedMilliseconds}ms\n'
                'Status: ${response.statusCode}\n'
                'Data: ${response.data.toString().substring(0, 100)}...';
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        result = '❌ Ошибка: $e';
      });
    }
  }
}