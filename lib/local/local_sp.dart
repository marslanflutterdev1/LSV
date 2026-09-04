import 'package:shared_preferences/shared_preferences.dart';

class LocalSP {
  LocalSP._();
  static SharedPreferences? sharedPreferences;
  static const String tokenKey = "key";

  /// Initialize SharedPreferences
  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

// =========================
// STRING
// =========================

  static Future<bool> setStringData(String key, String value) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.setString(key, value);
  }


  static String getStringData(String key) {
    if (sharedPreferences == null) return '';

    return sharedPreferences!.getString(key) ?? '';
  }

  static Future<bool> updateStringData(String key, String value) async {
    if (sharedPreferences == null || !sharedPreferences!.containsKey(key)) {
      return false;
    }

    return await setStringData(key, value);
  }

  static Future<bool> removeStringData(String key) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.remove(key);
  }

  // =========================
  // INT
  // =========================

  static Future<bool> setIntData(String key, int value) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.setInt(key, value);
  }

  static int getIntData(String key) {
    if (sharedPreferences == null) return 0;

    return sharedPreferences!.getInt(key) ?? 0;
  }

  static Future<bool> updateIntData(String key, int value) async {
    if (sharedPreferences == null || !sharedPreferences!.containsKey(key)) {
      return false;
    }

    return await setIntData(key, value);
  }

  static Future<bool> removeIntData(String key) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.remove(key);
  }

  // =========================
  // DOUBLE
  // =========================

  static Future<bool> setDoubleData(String key, double value) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.setDouble(key, value);
  }

  static double getDoubleData(String key) {
    if (sharedPreferences == null) return 0.0;

    return sharedPreferences!.getDouble(key) ?? 0.0;
  }

  static Future<bool> updateDoubleData(String key, double value) async {
    if (sharedPreferences == null || !sharedPreferences!.containsKey(key)) {
      return false;
    }

    return await setDoubleData(key, value);
  }

  static Future<bool> removeDoubleData(String key) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.remove(key);
  }

  // =========================
  // BOOL
  // =========================

  static Future<bool> setBoolData(String key, bool value) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.setBool(key, value);
  }

  static bool getBoolData(String key) {
    if (sharedPreferences == null) return false;

    return sharedPreferences!.getBool(key) ?? false;
  }

  static Future<bool> updateBoolData(String key, bool value) async {
    if (sharedPreferences == null || !sharedPreferences!.containsKey(key)) {
      return false;
    }

    return await setBoolData(key, value);
  }

  static Future<bool> removeBoolData(String key) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.remove(key);
  }

  // =========================
  // STRING LIST
  // =========================

  static Future<bool> setStringListData(String key, List<String> value) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.setStringList(key, value);
  }

  static List<String> getStringListData(String key) {
    if (sharedPreferences == null) return [];

    return sharedPreferences!.getStringList(key) ?? [];
  }

  static Future<bool> updateStringListData(String key, List<String> value) async {
    if (sharedPreferences == null || !sharedPreferences!.containsKey(key)) {
      return false;
    }

    return await setStringListData(key, value);
  }

  static Future<bool> removeStringListData(String key) async {
    if (sharedPreferences == null) return false;

    return await sharedPreferences!.remove(key);
  }


  /// Clear All Data
  static Future<bool> clearAllData() async {
    if (sharedPreferences == null) return false;
    return await sharedPreferences!.clear();
  }
}
