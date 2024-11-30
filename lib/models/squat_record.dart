class SquatRecord {
  final int id;
  final DateTime dateTime;
  final int count;
  final double accuracy;
  final Duration duration;

  const SquatRecord({
    required this.id,
    required this.dateTime,
    required this.count,
    required this.accuracy,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'count': count,
      'accuracy': accuracy,
      'duration': duration.inSeconds,
    };
  }

  factory SquatRecord.fromMap(Map<String, dynamic> map) {
    return SquatRecord(
      id: map['id'],
      dateTime: DateTime.parse(map['dateTime']),
      count: map['count'],
      accuracy: map['accuracy'],
      duration: Duration(seconds: map['duration']),
    );
  }
}
