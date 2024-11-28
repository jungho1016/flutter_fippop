import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('프로필 설정'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 프로필 설정 페이지로 이동
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('알림 설정'),
                  trailing: Switch(
                    value: true, // 알림 상태값 연동 필요
                    onChanged: (value) {
                      // 알림 설정 변경 처리
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('다크 모드'),
                  trailing: Switch(
                    value: false, // 테마 상태값 연동 필요
                    onChanged: (value) {
                      // 테마 변경 처리
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
