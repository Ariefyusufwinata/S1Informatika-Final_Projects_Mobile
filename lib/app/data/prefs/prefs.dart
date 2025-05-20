import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late SharedPreferences _prefs;

  // constant
  static String login = 'login';
  static String firstTime = 'firstTime';

  // inits
  static Future<SharedPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs;
  }

  // sets
  static Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  static Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);

  // For set object shared data
  static Future<bool> setObject(String key, value) async =>
      await _prefs.setString(key, jsonEncode(value));

  // For set is login user
  static Future<bool> setLogin(String key, bool value) async =>
      await _prefs.setBool(key, value);

  // For set is firsTime running
  static Future<bool> setIsFirstTime(String key, bool value) async =>
      await _prefs.setBool(key, value);

  //gets
  static String? getString(String key) => _prefs.getString(key);

  static int? getInt(String key) => _prefs.getInt(key);

  // For Object
  static getObject(String key) => _prefs.getString(key);

  // For get is login user
  static bool getLogin() => _prefs.getBool(login) ?? false;

  // For check is firstTime running
  static bool getFirstTime() => _prefs.getBool(firstTime) ?? true;

  //remove
  static Future<bool> remove(String key) async => await _prefs.remove(key);
}
