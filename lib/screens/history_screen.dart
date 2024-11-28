import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/workout_session.dart';
import '../services/database_helper.dart';
import '../services/share_service.dart';
import '../widgets/workout_session_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutSession> workoutSessions = [];

  @override
  void initState() {
    super.initState();
    _loadWorkoutSessions();
  }

  Future<void> _loadWorkoutSessions() async {
    final sessions = await DatabaseHelper.instance.getWorkoutSessions();
    setState(() {
      workoutSessions = sessions;
    });
  }

  void _showDetailDialog(BuildContext context, WorkoutSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 상세 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('날짜: ${session.startTime.toString().split(' ')[0]}'),
            Text('스쿼트: ${session.squatCount}회'),
            Text('정확도: ${session.accuracy.toStringAsFixed(1)}%'),
            Text('소요시간: ${session.averageDuration.toStringAsFixed(1)}초'),
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

  void _showAchievements(BuildContext context) {
    Navigator.pushNamed(context, '/achievements');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('운동 기록'),
              background: _buildWeeklyChart(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => Navigator.pushNamed(context, '/calendar'),
              ),
              IconButton(
                icon: const Icon(Icons.emoji_events),
                onPressed: () => _showAchievements(context),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = workoutSessions[index];
                return WorkoutSessionCard(
                  session: session,
                  onTap: () => _showDetailDialog(context, session),
                  onShare: () => ShareService.shareWorkoutResults(session),
                );
              },
              childCount: workoutSessions.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['월', '화', '수', '목', '금', '토', '일'];
                  return Text(days[value.toInt()]);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            // 예시 데이터
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 30)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 45)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 60)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 40)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 55)]),
            BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 70)]),
            BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 65)]),
          ],
        ),
      ),
    );
  }
}
