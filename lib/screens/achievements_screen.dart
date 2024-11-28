import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/achievement_badge.dart';
import '../services/achievement_service.dart';
import '../services/share_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<AchievementBadge> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final achievements = await AchievementService.instance.getAchievements();
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업적을 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('업적'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareUnlockedAchievements(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _achievements.isEmpty
              ? _buildEmptyState()
              : _buildAchievementsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '아직 획득한 업적이 없습니다.\n운동을 시작해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Card(
          child: ListTile(
            leading: _buildAchievementIcon(achievement),
            title: Text(
              achievement.title,
              style: TextStyle(
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              achievement.description,
              style: TextStyle(
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),
            trailing: achievement.isUnlocked
                ? Text(
                    achievement.unlockedAt?.toString().split(' ')[0] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  )
                : const Icon(Icons.lock, color: Colors.grey),
            onTap: achievement.isUnlocked
                ? () => _showAchievementDetails(achievement)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAchievementIcon(AchievementBadge achievement) {
    return Stack(
      children: [
        Image.asset(
          achievement.iconPath,
          width: 40,
          height: 40,
          color: achievement.isUnlocked ? null : Colors.grey,
        ),
        if (achievement.isUnlocked)
          const Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.check_circle, color: Colors.green, size: 16),
          ),
      ],
    );
  }

  void _showAchievementDetails(AchievementBadge achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(achievement.iconPath, width: 100, height: 100),
            const SizedBox(height: 16),
            Text(achievement.description),
            const SizedBox(height: 8),
            Text(
              '획득: ${achievement.unlockedAt?.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              ShareService.shareAchievement(achievement.title);
              Navigator.pop(context);
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareUnlockedAchievements() async {
    final unlockedAchievements =
        _achievements.where((a) => a.isUnlocked).toList();
    if (unlockedAchievements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 획득한 업적이 없습니다.')),
      );
      return;
    }

    final shareText = '''
🏆 나의 업적
총 ${unlockedAchievements.length}개의 업적 획득!

${unlockedAchievements.map((a) => '- ${a.title}').join('\n')}
''';

    await Share.share(shareText);
  }
}
