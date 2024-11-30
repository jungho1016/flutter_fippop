import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/squat_record.dart';
import '../models/workout_stats.dart';

class HomeScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스쿼트 카운터'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: FutureBuilder<List<SquatRecord>>(
        future: _databaseService.getRecords(),
        builder: (context, snapshot) {
          final hasRecords = snapshot.hasData && snapshot.data!.isNotEmpty;
          final stats = hasRecords
              ? WorkoutStats.fromRecords(snapshot.data!)
              : const WorkoutStats(totalSquats: 0, averageAccuracy: 0);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasRecords) ...[
                  Text(
                    '총 ${stats.totalSquats}회',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '평균 정확도 ${stats.averageAccuracy.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                ],
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/camera'),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('운동 시작하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('운동 기록 보기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
