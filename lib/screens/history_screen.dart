import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../services/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat dateFormat = DateFormat('MM/dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '일간'),
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyStats(),
          _buildWeeklyStats(),
          _buildMonthlyStats(),
        ],
      ),
    );
  }

  Widget _buildDailyStats() {
    return FutureBuilder<List<WorkoutSession>>(
      future: DatabaseHelper.instance.getAllWorkoutSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('아직 운동 기록이 없습니다.'));
        }

        final sessions = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCard(sessions),
              const SizedBox(height: 16),
              _buildSquatChart(sessions),
              const SizedBox(height: 16),
              _buildSessionList(sessions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(List<WorkoutSession> sessions) {
    final totalSquats =
        sessions.fold<int>(0, (sum, session) => sum + session.squatCount);
    final avgAccuracy =
        sessions.fold<double>(0, (sum, session) => sum + session.accuracy) /
            sessions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '오늘의 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('총 스쿼트', '$totalSquats회'),
                _buildStatItem('평균 정확도', '${avgAccuracy.toStringAsFixed(1)}%'),
                _buildStatItem('운동 횟수', '${sessions.length}회'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSquatChart(List<WorkoutSession> sessions) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sessions.length) return const Text('');
                  return Text(
                    dateFormat.format(sessions[value.toInt()].startTime),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: sessions.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.squatCount.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<WorkoutSession> sessions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final duration = session.endTime.difference(session.startTime);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${session.squatCount}'),
            ),
            title: Text('${dateFormat.format(session.startTime)} 운동'),
            subtitle: Text(
              '시간: ${duration.inMinutes}분\n정확도: ${session.accuracy.toStringAsFixed(1)}%',
            ),
            trailing: Icon(
              _getAccuracyIcon(session.accuracy),
              color: _getAccuracyColor(session.accuracy),
            ),
          ),
        );
      },
    );
  }

  IconData _getAccuracyIcon(double accuracy) {
    if (accuracy >= 90) return Icons.emoji_events;
    if (accuracy >= 70) return Icons.thumb_up;
    return Icons.fitness_center;
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.amber;
    if (accuracy >= 70) return Colors.green;
    return Colors.blue;
  }

  Widget _buildWeeklyStats() {
    return FutureBuilder<List<WorkoutSession>>(
      future: DatabaseHelper.instance.getAllWorkoutSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!;
        final weeklyData = _groupSessionsByWeek(sessions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWeeklyChart(weeklyData),
              const SizedBox(height: 16),
              _buildWeeklyList(weeklyData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyStats() {
    return FutureBuilder<List<WorkoutSession>>(
      future: DatabaseHelper.instance.getAllWorkoutSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!;
        final monthlyData = _groupSessionsByMonth(sessions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMonthlyChart(monthlyData),
              const SizedBox(height: 16),
              _buildMonthlyList(monthlyData),
            ],
          ),
        );
      },
    );
  }

  Map<DateTime, List<WorkoutSession>> _groupSessionsByWeek(
      List<WorkoutSession> sessions) {
    final Map<DateTime, List<WorkoutSession>> weeklyData = {};

    for (var session in sessions) {
      final weekStart = _getWeekStart(session.startTime);
      weeklyData.putIfAbsent(weekStart, () => []);
      weeklyData[weekStart]!.add(session);
    }

    return Map.fromEntries(
        weeklyData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  Map<DateTime, List<WorkoutSession>> _groupSessionsByMonth(
      List<WorkoutSession> sessions) {
    final Map<DateTime, List<WorkoutSession>> monthlyData = {};

    for (var session in sessions) {
      final monthStart =
          DateTime(session.startTime.year, session.startTime.month, 1);
      monthlyData.putIfAbsent(monthStart, () => []);
      monthlyData[monthStart]!.add(session);
    }

    return Map.fromEntries(
        monthlyData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildWeeklyChart(Map<DateTime, List<WorkoutSession>> weeklyData) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= weeklyData.length) return const Text('');
                  final date = weeklyData.keys.elementAt(value.toInt());
                  return Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: weeklyData.entries.map((entry) {
                final totalSquats = entry.value
                    .fold<int>(0, (sum, session) => sum + session.squatCount);
                return FlSpot(
                  weeklyData.keys.toList().indexOf(entry.key).toDouble(),
                  totalSquats.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<DateTime, List<WorkoutSession>> monthlyData) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= monthlyData.length)
                    return const Text('');
                  final date = monthlyData.keys.elementAt(value.toInt());
                  return Text(
                    '${date.year}/${date.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: monthlyData.entries.map((entry) {
                final totalSquats = entry.value
                    .fold<int>(0, (sum, session) => sum + session.squatCount);
                return FlSpot(
                  monthlyData.keys.toList().indexOf(entry.key).toDouble(),
                  totalSquats.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyList(Map<DateTime, List<WorkoutSession>> weeklyData) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeklyData.length,
      itemBuilder: (context, index) {
        final entry = weeklyData.entries.elementAt(index);
        final weekStart = entry.key;
        final sessions = entry.value;

        final totalSquats =
            sessions.fold<int>(0, (sum, session) => sum + session.squatCount);
        final avgAccuracy =
            sessions.fold<double>(0, (sum, session) => sum + session.accuracy) /
                sessions.length;

        return Card(
          child: ListTile(
            title: Text('${weekStart.month}/${weekStart.day} 주간'),
            subtitle: Text(
              '총 스쿼트: $totalSquats회\n'
              '평균 정확도: ${avgAccuracy.toStringAsFixed(1)}%\n'
              '운동 횟수: ${sessions.length}회',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildMonthlyList(Map<DateTime, List<WorkoutSession>> monthlyData) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        final entry = monthlyData.entries.elementAt(index);
        final monthStart = entry.key;
        final sessions = entry.value;

        final totalSquats =
            sessions.fold<int>(0, (sum, session) => sum + session.squatCount);
        final avgAccuracy =
            sessions.fold<double>(0, (sum, session) => sum + session.accuracy) /
                sessions.length;

        return Card(
          child: ListTile(
            title: Text('${monthStart.year}년 ${monthStart.month}월'),
            subtitle: Text(
              '총 스쿼트: $totalSquats회\n'
              '평균 정확도: ${avgAccuracy.toStringAsFixed(1)}%\n'
              '운동 횟수: ${sessions.length}회',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
