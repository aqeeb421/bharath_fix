import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static LocalStorage? _instance;
  static SharedPreferences? _prefs;

  // Storage keys
  static const String firstUse = "firstUse";
  static const String userData = "user_data";
  static const String eLostReport = "eLostReport";
  static const String eLostArticles = "eLostArticles";
  static const String LANGUAGE = "language";
  static const String APP_USER = "APP_USER";
  static const String PASSWORD = "PASSWORD";
  static const String termsURL = "termsURL";
  static const String allowed_features = "allowed_features";

  static const String AUTH = "AUTH";
  static const String LOCAL_PASSWORD = "LOCAL_PASSWORD";
  static const String CHANGE_DB_PASSWORD = "CHANGE_DB_PASSWORD";
  static const String DATABASE_PASSWORD = "DATABASE_PASSWORD";
  static const String IS_OTP_CHECK = "IS_OTP_CHECK";
  static const String SMS_RETRIVER_FLAG = "SMS_RETRIVER_FLAG";
  static const String ENCRYPTED_VALUE = "ENCRYPTED_VALUE";
  static const String DISTRICT = "DISTRICT";
  static const String USER_JURISDICTION = "USER_JURISDICTION";
  static const String DATA_INITIALIZED = "DATA_INITIALIZED";
  static const String V24_INIT = "V24_INIT";
  static const String DATA_VERSION = "DATA_VERSION";
  static const String SUBSCRIBED_TOPICS = "SUBSCRIBED_TOPICS";
  static const String APP_LATEST_VERSION = "APP_LATEST_VERSION";

  static const String RSA_PUBLIC_KEY = "RSA_PUBLIC_KEY";
  static const String RSA_PRIVATE_KEY = "RSA_PRIVATE_KEY";
  static const String JWT = "JWT";
  static const String MOBILE = "MOBILE";
  static const String SERVER_PUBLIC_KEY = "SERVER_PUBLIC_KEY";
  static const String IS_POLICE_OFFICER = "IS_POLICE_OFFICER";
  static const String SERVER_STATUS = "SERVER_STATUS ";

  static const String biometric_enabled = "biometric_enabled";
  static const String user_pin = "user_pin";
  static const String pin_enabled = "pin_enabled";

  static const String SELECTED_YEAR = "SELECTED_YEAR";
  static const String DATA_DOWNLOADED_YEARS = "DATA_DOWNLOADED_YEARS";

  // Private constructor
  LocalStorage._();

  // Singleton instance
  static Future<LocalStorage> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorage._();
      _prefs = await SharedPreferences.getInstance();
      await _instance!._initializeDefaults(); // Load defaults
    }
    return _instance!;
  }

  /// Initialize default values
  Future<void> _initializeDefaults() async {
    // Helper to check if a key already exists
    Future<bool> hasKey(String key) async {
      return _prefs!.containsKey(key);
    }

    if (!await hasKey(firstUse)) {
      await setString(firstUse, "true");
    }

    if (!await hasKey(biometric_enabled)) {
      await setBool(biometric_enabled, false);
    }

    if (!await hasKey(user_pin)) {
      await setString(user_pin, "");
    }

    if (!await hasKey(SELECTED_YEAR)) {
      await setString(SELECTED_YEAR, "");
    }

    if (!await hasKey(DATA_DOWNLOADED_YEARS)) {
      await setString(DATA_DOWNLOADED_YEARS, "");
    }

    if (!await hasKey(pin_enabled)) {
      await setBool(pin_enabled, false);
    }

    if (!await hasKey(SERVER_STATUS)) {
      await setBool(SERVER_STATUS, false);
    }

    // only set defaults if not already stored
    if (!await hasKey(userData)) await setString(userData, "");
    if (!await hasKey(LANGUAGE)) await setString(LANGUAGE, "");
    if (!await hasKey(termsURL)) await setString(termsURL, "");
    if (!await hasKey(eLostReport)) await setString(eLostReport, "");
    if (!await hasKey(eLostArticles)) await setString(eLostArticles, "");
    if (!await hasKey(RSA_PUBLIC_KEY)) await setString(RSA_PUBLIC_KEY, "");
    if (!await hasKey(RSA_PRIVATE_KEY)) await setString(RSA_PRIVATE_KEY, "");
    if (!await hasKey(JWT)) await setString(JWT, "");
    if (!await hasKey(MOBILE)) await setString(MOBILE, "");
    if (!await hasKey(SERVER_PUBLIC_KEY))
      await setString(SERVER_PUBLIC_KEY, "");
    if (!await hasKey(AUTH)) await setString(AUTH, "");
    if (!await hasKey(LOCAL_PASSWORD)) await setString(LOCAL_PASSWORD, "");
    if (!await hasKey(CHANGE_DB_PASSWORD))
      await setString(CHANGE_DB_PASSWORD, "");
    if (!await hasKey(DATABASE_PASSWORD))
      await setString(DATABASE_PASSWORD, "");
    if (!await hasKey(IS_OTP_CHECK)) await setString(IS_OTP_CHECK, "false");
    if (!await hasKey(SMS_RETRIVER_FLAG))
      await setString(SMS_RETRIVER_FLAG, "false");
    if (!await hasKey(ENCRYPTED_VALUE)) await setString(ENCRYPTED_VALUE, "");
    if (!await hasKey(DISTRICT)) await setString(DISTRICT, "");
    if (!await hasKey(USER_JURISDICTION))
      await setString(USER_JURISDICTION, "");
    if (!await hasKey(DATA_INITIALIZED))
      await setString(DATA_INITIALIZED, "false");
    if (!await hasKey(V24_INIT)) await setString(V24_INIT, "false");
    if (!await hasKey(DATA_VERSION)) await setString(DATA_VERSION, "");
    if (!await hasKey(SUBSCRIBED_TOPICS))
      await setString(SUBSCRIBED_TOPICS, "");
    if (!await hasKey(APP_LATEST_VERSION))
      await setString(APP_LATEST_VERSION, "");
    if (!await hasKey(allowed_features)) await setString(allowed_features, "");
  }

  // Store a plain string (no encryption)
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      return false;
    }
  }

  // Retrieve a plain string (no decryption)
  Future<String?> getString(String key) async {
    try {
      return _prefs!.getString(key);
    } catch (e) {
      return null;
    }
  }

  // Store a plain bool (no encryption)
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      return false;
    }
  }

  // Retrieve a plain bool (no decryption)
  Future<bool?> getBool(String key) async {
    try {
      return _prefs!.getBool(key);
    } catch (e) {
      return null;
    }
  }

  // Clear all saved data and reinitialize defaults
  Future<void> clear() async {
    try {
      await _prefs?.clear();
      await _initializeDefaults(); // Reassign defaults after clearing
    } catch (e) {
      // ignore
    }
  }
}
