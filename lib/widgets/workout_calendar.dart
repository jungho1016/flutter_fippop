import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/squat_record.dart';

class WorkoutCalendar extends StatelessWidget {
  final List<SquatRecord> records;
  final Function(DateTime, DateTime) onDaySelected;

  const WorkoutCalendar({
    super.key,
    required this.records,
    required this.onDaySelected,
  });

  Map<DateTime, List<SquatRecord>> get _groupedRecords {
    final grouped = <DateTime, List<SquatRecord>>{};
    for (var record in records) {
      final date = DateTime(
        record.dateTime.year,
        record.dateTime.month,
        record.dateTime.day,
      );
      grouped.update(
        date,
        (list) => list..add(record),
        ifAbsent: () => [record],
      );
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.now(),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) => _groupedRecords[day] ?? [],
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          final count = (events as List<SquatRecord>)
              .fold<int>(0, (sum, record) => sum + record.count);
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            width: 16,
            height: 16,
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
      onDaySelected: onDaySelected,
    );
  }
}
