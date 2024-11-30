import 'package:flutter/material.dart';
import '../models/workout_stats.dart';

class WorkoutStatsWidget extends StatelessWidget {
  final WorkoutStats stats;

  const WorkoutStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('총 스쿼트: ${stats.totalSquats}회'),
            Text('평균 정확도: ${stats.averageAccuracy.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
