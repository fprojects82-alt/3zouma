import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Grocery apps a shopping list can be sent to.
enum GroceryStore { talabat, carrefour, breadfast }

/// The cook's preferences, saved on the device.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final SharedPreferences? _prefs;

  bool get chosenLanguage => _prefs?.getBool('chosen_language') ?? false;
  bool get arabic => _prefs?.getBool('arabic') ?? true;
  bool get voiceArabic => _prefs?.getBool('voice_arabic') ?? arabic;
  bool get voiceOn => _prefs?.getBool('voice_on') ?? true;
  bool get readAloud => _prefs?.getBool('read_aloud') ?? false;
  bool get easternNumerals => _prefs?.getBool('eastern_numerals') ?? arabic;
  GroceryStore get store => GroceryStore.values[(_prefs?.getInt('store') ?? 0).clamp(0, GroceryStore.values.length - 1)];

  Future<void> setLanguage(bool arabic) async {
    await _prefs?.setBool('arabic', arabic);
    await _prefs?.setBool('chosen_language', true);
    // Voice and numerals follow the screen language until set on their own.
    if (_prefs?.containsKey('voice_arabic') != true) await _prefs?.setBool('voice_arabic', arabic);
    if (_prefs?.containsKey('eastern_numerals') != true) await _prefs?.setBool('eastern_numerals', arabic);
    notifyListeners();
  }

  Future<void> setVoiceArabic(bool v) => _set('voice_arabic', v);
  Future<void> setVoiceOn(bool v) => _set('voice_on', v);
  Future<void> setReadAloud(bool v) => _set('read_aloud', v);
  Future<void> setEasternNumerals(bool v) => _set('eastern_numerals', v);

  Future<void> setStore(GroceryStore s) async {
    await _prefs?.setInt('store', s.index);
    notifyListeners();
  }

  Future<void> _set(String key, bool v) async {
    await _prefs?.setBool(key, v);
    notifyListeners();
  }
}
