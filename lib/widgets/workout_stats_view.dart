import 'package:flutter/material.dart';
import '../models/workout_stats.dart';

class WorkoutStatsView extends StatelessWidget {
  final WorkoutStats stats;

  const WorkoutStatsView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOverallStats(context),
        const Divider(height: 32),
        _buildAccuracyChart(context),
      ],
    );
  }

  Widget _buildOverallStats(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전체 통계', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.fitness_center,
              label: '총 스쿼트',
              value: '${stats.totalSquats}회',
            ),
            _buildStatRow(
              icon: Icons.speed,
              label: '평균 정확도',
              value: '${stats.averageAccuracy.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyChart(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정확도 분포', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '${stats.averageAccuracy.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
