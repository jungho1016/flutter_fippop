import 'squat_record.dart';

class WorkoutStats {
  final int totalSquats;
  final double averageAccuracy;

  const WorkoutStats({
    required this.totalSquats,
    required this.averageAccuracy,
  });

  factory WorkoutStats.fromRecords(List<SquatRecord> records) {
    if (records.isEmpty) {
      return const WorkoutStats(totalSquats: 0, averageAccuracy: 0);
    }

    final totalSquats = records.fold(0, (sum, record) => sum + record.count);
    final averageAccuracy =
        records.fold(0.0, (sum, record) => sum + record.accuracy) /
            records.length;

    return WorkoutStats(
        totalSquats: totalSquats, averageAccuracy: averageAccuracy);
  }
}
