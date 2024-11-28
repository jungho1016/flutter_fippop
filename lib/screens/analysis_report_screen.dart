import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisReportScreen extends StatelessWidget {
  const AnalysisReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자세 분석 리포트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverallScore(),
            _buildPostureAnalysis(),
            _buildImprovementSuggestions(),
            _buildProgressChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('전체 자세 점수', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            CircularProgressIndicator(value: 0.85),
            Text('85/100',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostureAnalysis() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('자세 분석', style: TextStyle(fontSize: 18)),
            // 자세 분석 내용
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('개선 제안', style: TextStyle(fontSize: 18)),
            // 개선 제안 내용
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('주간 진행 상황', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['월', '화', '수', '목', '금', '토', '일'];
                          return Text(days[value.toInt() % 7]);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 80),
                        const FlSpot(1, 85),
                        const FlSpot(2, 82),
                        const FlSpot(3, 88),
                        const FlSpot(4, 85),
                        const FlSpot(5, 90),
                        const FlSpot(6, 87),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
