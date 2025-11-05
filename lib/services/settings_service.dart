// lib/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  // Clés de stockage
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyFontSize = 'font_size';
  static const String _keyLanguage = 'language';

  // ========== THÈME ==========

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // ========== TAILLE DE POLICE ==========

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 1.0;
  }

  Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, value);
  }

  // ========== LANGUE ==========

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'fr';
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  // ========== RÉINITIALISER ==========

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyFontSize);
    await prefs.remove(_keyLanguage);
  }
}