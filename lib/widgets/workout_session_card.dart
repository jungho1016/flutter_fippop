import 'package:flutter/material.dart';
import '../models/workout_session.dart';

class WorkoutSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const WorkoutSessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text('스쿼트 ${session.squatCount}회'),
        subtitle: Text(
          '정확도: ${session.accuracy.toStringAsFixed(1)}% • ${session.averageDuration.toStringAsFixed(1)}초',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShare,
        ),
      ),
    );
  }
}
