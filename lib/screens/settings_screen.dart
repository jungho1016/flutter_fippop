import 'package:flutter/material.dart';
import '../services/export_service.dart';
import 'goal_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('프로필 설정'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // 프로필 설정 페이지로 이동
              },
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('알림 설정'),
                  trailing: Switch(
                    value: true, // 알림 상태값 연동 필요
                    onChanged: (value) {
                      // 알림 설정 변경 처리
                    },
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text('다크 모드'),
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
