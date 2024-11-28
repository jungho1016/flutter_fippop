import 'package:flutter/material.dart';
import '../models/exercise_intensity.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ExerciseIntensity _intensity = ExerciseIntensity.medium;
  int _targetSquats = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('운동 강도'),
            subtitle: Text(_intensity.displayName),
            onTap: _showIntensityDialog,
          ),
          ListTile(
            title: const Text('목표 스쿼트 횟수'),
            subtitle: Text('$_targetSquats회'),
            onTap: _showTargetSquatsDialog,
          ),
        ],
      ),
    );
  }

  void _showIntensityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 강도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExerciseIntensity.values.map((intensity) {
            return RadioListTile<ExerciseIntensity>(
              title: Text(intensity.displayName),
              value: intensity,
              groupValue: _intensity,
              onChanged: (value) {
                setState(() {
                  _intensity = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTargetSquatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 스쿼트 횟수'),
        content: TextField(
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            setState(() {
              _targetSquats = int.tryParse(value) ?? _targetSquats;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
