import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _langKey = 'app_language_code';
  final ValueNotifier<String> currentLangNotifier = ValueNotifier<String>('en');

  String get currentLanguage => currentLangNotifier.value;
  bool get isKannada => currentLangNotifier.value == 'kn';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey) ?? 'en';
    currentLangNotifier.value = lang;
  }

  Future<void> setLanguage(String langCode) async {
    currentLangNotifier.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
  }

  String translate(String key) {
    return AppTranslations.getText(key, currentLangNotifier.value);
  }
}
