import 'package:flutter/material.dart';
import '../models/workout_session.dart';

class WorkoutSessionTile extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;

  const WorkoutSessionTile({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text('스쿼트 ${session.squatCount}회'),
      subtitle: Text(
        '정확도: ${session.accuracy.toStringAsFixed(1)}%',
      ),
      trailing: Text(
        '${session.averageDuration.toStringAsFixed(1)}초',
      ),
    );
  }
}
