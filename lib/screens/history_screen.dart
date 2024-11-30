import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/squat_record.dart';
import '../models/workout_stats.dart';
import '../services/database_service.dart';
import '../widgets/workout_calendar.dart';
import '../widgets/workout_stats_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  String _sortBy = 'date'; // 'date', 'count', 'accuracy'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SquatRecord> _sortRecords(List<SquatRecord> records) {
    switch (_sortBy) {
      case 'date':
        records.sort((a, b) => _sortAscending
            ? a.dateTime.compareTo(b.dateTime)
            : b.dateTime.compareTo(a.dateTime));
        break;
      case 'count':
        records.sort((a, b) => _sortAscending
            ? a.count.compareTo(b.count)
            : b.count.compareTo(a.count));
        break;
      case 'accuracy':
        records.sort((a, b) => _sortAscending
            ? a.accuracy.compareTo(b.accuracy)
            : b.accuracy.compareTo(a.accuracy));
        break;
    }
    return records;
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('운동 기록'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            setState(() {
              if (_sortBy == value) {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = value;
                _sortAscending = true;
              }
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'date',
              child: Text('날짜순'),
            ),
            const PopupMenuItem(
              value: 'count',
              child: Text('횟수순'),
            ),
            const PopupMenuItem(
              value: 'accuracy',
              child: Text('정확도순'),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '달력'),
          Tab(text: '통계'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FutureBuilder<List<SquatRecord>>(
        future: _databaseService.getRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('아직 기록이 없습니다'));
          }

          final records = snapshot.data!;
          final sortedRecords = _sortRecords(records);
          final stats = WorkoutStats.fromRecords(sortedRecords);

          return TabBarView(
            controller: _tabController,
            children: [
              // 달력 뷰
              Column(
                children: [
                  WorkoutCalendar(
                    records: records,
                    onDaySelected: (selectedDay, focusedDay) =>
                        setState(() => _selectedDate = selectedDay),
                  ),
                  const Divider(),
                  _buildDayRecords(),
                ],
              ),
              // 통계 뷰
              SingleChildScrollView(
                child: WorkoutStatsView(stats: stats),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayRecords() {
    return Expanded(
      child: FutureBuilder<List<SquatRecord>>(
        future: _databaseService.getRecordsByDate(_selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final dayRecords = snapshot.data!;
          if (dayRecords.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('이 날의 운동 기록이 없습니다'),
            );
          }

          return ListView.builder(
            itemCount: dayRecords.length,
            itemBuilder: (context, index) {
              final record = dayRecords[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${record.count}회'),
                ),
                title: Text(
                  '${record.dateTime.hour}:${record.dateTime.minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('운동 시간: ${record.duration.inSeconds}초'),
                    Text('정확도: ${record.accuracy.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareRecord(record),
                ),
                onLongPress: () async {
                  final delete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('기록 삭제'),
                      content: const Text('이 운동 기록을 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );

                  if (delete == true && mounted) {
                    await _databaseService.deleteRecord(record.id);
                    setState(() {}); // 화면 갱신
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('기록이 삭제되었습니다')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _shareRecord(SquatRecord record) {
    final dateStr =
        '${record.dateTime.year}.${record.dateTime.month}.${record.dateTime.day}';
    final timeStr =
        '${record.dateTime.hour}:${record.dateTime.minute.toString().padLeft(2, '0')}';
    final message = '''
스쿼트 운동 기록 ($dateStr $timeStr)
- 운동 횟수: ${record.count}회
- 운동 시간: ${record.duration.inSeconds}초
- 정확도: ${record.accuracy.toStringAsFixed(1)}%
''';
    Share.share(message);
  }
}
