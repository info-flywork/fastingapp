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
}
