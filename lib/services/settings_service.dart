import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _targetSquatsKey = 'targetSquats';
  static const String _useSoundKey = 'useSound';
  static const String _showGuideKey = 'showGuide';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      targetSquats: prefs.getInt(_targetSquatsKey) ?? 20,
      useSound: prefs.getBool(_useSoundKey) ?? true,
      showGuide: prefs.getBool(_showGuideKey) ?? true,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetSquatsKey, settings.targetSquats);
    await prefs.setBool(_useSoundKey, settings.useSound);
    await prefs.setBool(_showGuideKey, settings.showGuide);
  }
}
