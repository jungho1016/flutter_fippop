import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final _settingsService = SettingsService();
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  SettingsProvider() {
    _loadSettings();
  }

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> _loadSettings() async {
    _settings = await _settingsService.loadSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    await _settingsService.saveSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }
}
