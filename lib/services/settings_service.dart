// lib/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  // Clés de stockage
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyFontSize = 'font_size';
  static const String _keyLanguage = 'language';

  // Cache des valeurs pour éviter trop de lectures
  bool? _cachedDarkMode;
  double? _cachedFontSize;
  String? _cachedLanguage;

  // ========== THÈME ==========

  Future<bool> isDarkMode() async {
    if (_cachedDarkMode != null) return _cachedDarkMode!;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    return _cachedDarkMode!;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    _cachedDarkMode = value;
    
    // ✅ Notifier les listeners (le main.dart va se rebuild)
    notifyListeners();
    
    print('✅ Mode ${value ? 'sombre' : 'clair'} sauvegardé');
  }

  // ========== TAILLE DE POLICE ==========

  Future<double> getFontSize() async {
    if (_cachedFontSize != null) return _cachedFontSize!;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedFontSize = prefs.getDouble(_keyFontSize) ?? 1.0;
    return _cachedFontSize!;
  }

  Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, value);
    _cachedFontSize = value;
    
    notifyListeners();
    
    print('✅ Taille de police: $value sauvegardée');
  }

  // ========== LANGUE ==========

  Future<String> getLanguage() async {
    if (_cachedLanguage != null) return _cachedLanguage!;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedLanguage = prefs.getString(_keyLanguage) ?? 'fr';
    return _cachedLanguage!;
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
    _cachedLanguage = value;
    
    notifyListeners();
    
    print('✅ Langue: $value sauvegardée');
  }

  // ========== RÉINITIALISER ==========

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyFontSize);
    await prefs.remove(_keyLanguage);
    
    // Réinitialiser le cache
    _cachedDarkMode = null;
    _cachedFontSize = null;
    _cachedLanguage = null;
    
    notifyListeners();
    
    print('✅ Tous les paramètres réinitialisés');
  }

  // ========== MÉTHODES UTILITAIRES ==========

  // Obtenir tous les paramètres d'un coup
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'darkMode': await isDarkMode(),
      'fontSize': await getFontSize(),
      'language': await getLanguage(),
    };
  }

  // Afficher les paramètres actuels (debug)
  Future<void> printCurrentSettings() async {
    final settings = await getAllSettings();
    print('📋 Paramètres actuels:');
    print('   Mode sombre: ${settings['darkMode']}');
    print('   Taille police: ${settings['fontSize']}');
    print('   Langue: ${settings['language']}');
  }
}