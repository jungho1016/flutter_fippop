import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = provider.settings;
          return ListView(
            children: [
              ListTile(
                title: const Text('목표 스쿼트 횟수'),
                subtitle: Text('${settings.targetSquats}회'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final count = await showDialog<int>(
                    context: context,
                    builder: (context) => _TargetSquatsDialog(
                      initialValue: settings.targetSquats,
                    ),
                  );
                  if (count != null) {
                    provider
                        .updateSettings(settings.copyWith(targetSquats: count));
                  }
                },
              ),
              SwitchListTile(
                title: const Text('음성 피드백'),
                subtitle: const Text('운동 중 음성으로 안내합니다'),
                value: settings.useSound,
                onChanged: (value) {
                  provider.updateSettings(settings.copyWith(useSound: value));
                },
              ),
              SwitchListTile(
                title: const Text('자세 가이드'),
                subtitle: const Text('올바른 자세를 안내합니다'),
                value: settings.showGuide,
                onChanged: (value) {
                  provider.updateSettings(settings.copyWith(showGuide: value));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TargetSquatsDialog extends StatefulWidget {
  final int initialValue;

  const _TargetSquatsDialog({required this.initialValue});

  @override
  State<_TargetSquatsDialog> createState() => _TargetSquatsDialogState();
}

class _TargetSquatsDialogState extends State<_TargetSquatsDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('목표 스쿼트 횟수'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          suffix: Text('회'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final count = int.tryParse(_controller.text);
            if (count != null && count > 0) {
              Navigator.pop(context, count);
            }
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
