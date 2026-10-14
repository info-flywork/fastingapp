import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences singleton sarmalayıcısı. (Doküman 8)
///
/// Kullanımdan önce [init] çağrılmalıdır (bkz. AppInit).
final class SharedPrefManager {
  SharedPrefManager._();

  static final SharedPrefManager instance = SharedPrefManager._();

  SharedPreferences? _prefs;

  SharedPreferences get _preferences {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SharedPrefManager.init() çağrılmadı.');
    }
    return prefs;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const _firstLaunchKey = 'first_launch';

  bool get isFirstLaunch => _preferences.getBool(_firstLaunchKey) ?? true;

  Future<void> setFirstLaunchDone() =>
      _preferences.setBool(_firstLaunchKey, false);

  static const _summaryKey = 'home_summary_cache';
  static const _summaryDayKey = 'home_summary_day';

  /// Son ana sayfa özeti (ham JSON) ve alındığı yerel gün `yyyy-MM-dd`.
  ({String json, String day})? get homeSummary {
    final json = _prefs?.getString(_summaryKey);
    final day = _prefs?.getString(_summaryDayKey);
    if (json == null || day == null) return null;
    return (json: json, day: day);
  }

  Future<void> setHomeSummary(String json, String day) async {
    await _preferences.setString(_summaryKey, json);
    await _preferences.setString(_summaryDayKey, day);
  }

  Future<void> clearHomeSummary() async {
    await _prefs?.remove(_summaryKey);
    await _prefs?.remove(_summaryDayKey);
  }
}
