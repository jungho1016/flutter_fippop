import 'package:flutter/material.dart';
import '../models/workout_goal.dart';
import '../services/goal_service.dart';

class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  late WorkoutGoal _currentGoal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
  }

  Future<void> _loadCurrentGoal() async {
    final goal = await GoalService.instance.getGoal();
    setState(() {
      _currentGoal = goal;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 목표 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '일일 목표',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    '스쿼트 횟수',
                    _currentGoal.dailySquatTarget.toDouble(),
                    10,
                    100,
                    (value) {
                      setState(() {
                        _currentGoal = WorkoutGoal(
                          dailySquatTarget: value.round(),
                          weeklySquatTarget: _currentGoal.weeklySquatTarget,
                          minAccuracy: _currentGoal.minAccuracy,
                          intensity: _currentGoal.intensity,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '운동 강도',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIntensitySelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '정확도 목표',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    '최소 정확도',
                    _currentGoal.minAccuracy,
                    50,
                    100,
                    (value) {
                      setState(() {
                        _currentGoal = WorkoutGoal(
                          dailySquatTarget: _currentGoal.dailySquatTarget,
                          weeklySquatTarget: _currentGoal.weeklySquatTarget,
                          minAccuracy: value,
                          intensity: _currentGoal.intensity,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('저장'),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIntensitySelector() {
    return SegmentedButton<ExerciseIntensity>(
      segments: const [
        ButtonSegment(
          value: ExerciseIntensity.easy,
          label: Text('쉬움'),
          icon: Icon(Icons.accessibility),
        ),
        ButtonSegment(
          value: ExerciseIntensity.medium,
          label: Text('보통'),
          icon: Icon(Icons.fitness_center),
        ),
        ButtonSegment(
          value: ExerciseIntensity.hard,
          label: Text('어려움'),
          icon: Icon(Icons.whatshot),
        ),
      ],
      selected: {_currentGoal.intensity},
      onSelectionChanged: (Set<ExerciseIntensity> selected) {
        setState(() {
          _currentGoal = WorkoutGoal(
            dailySquatTarget: _currentGoal.dailySquatTarget,
            weeklySquatTarget: _currentGoal.weeklySquatTarget,
            minAccuracy: _currentGoal.minAccuracy,
            intensity: selected.first,
          );
        });
      },
    );
  }

  Future<void> _saveGoal() async {
    try {
      await GoalService.instance.saveGoal(_currentGoal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표가 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 저장에 실패했습니다')),
        );
      }
    }
  }
}
