import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_session.dart';
import '../services/database_helper.dart';
import '../widgets/workout_session_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  List<WorkoutSession> sessions = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final loadedSessions = await DatabaseHelper.instance.getWorkoutSessions();
    setState(() {
      sessions = loadedSessions;
    });
  }

  List<WorkoutSession> _getWorkoutsForDay(DateTime day) {
    return sessions.where((session) {
      return session.startTime.year == day.year &&
          session.startTime.month == day.month &&
          session.startTime.day == day.day;
    }).toList();
  }

  void _showWorkoutDetails(BuildContext context, WorkoutSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 상세 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('스쿼트: ${session.squatCount}회'),
            Text('정확도: ${session.accuracy.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _selectedDay = day;
      _focusedDay = focusedDay;
    });
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 캘린더')),
      body: Column(
        children: [
          TableCalendar<WorkoutSession>(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getWorkoutsForDay,
            onDaySelected: _onDaySelected,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _buildWorkoutList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList() {
    final selectedDaySessions =
        _selectedDay != null ? _getWorkoutsForDay(_selectedDay!) : const [];

    return ListView.builder(
      itemCount: selectedDaySessions.length,
      itemBuilder: (context, index) {
        return WorkoutSessionTile(
          session: selectedDaySessions[index],
          onTap: () => _showWorkoutDetails(context, selectedDaySessions[index]),
        );
      },
    );
  }
}
