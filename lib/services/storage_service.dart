import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/shift.dart';

class StorageService {
  static const _shiftsKey = 'shiftPro_data';
  static const _goalsKey = 'goals_list';
  static const _goalNameKey = 'goal_name';
  static const _goalPriceKey = 'goal_price';
  static const _darkKey = 'isDark';
  static const _plusKey = 'isPlusPurchased';
  static const _promoKey = 'promo_expiry_ms';
  static const _currencyKey = 'app_currency';
  static const _taxPercentKey = 'tax_percent';
  static const _taxPeriodKey = 'tax_period';
  static const _toggleBonusKey = 'toggle_bonus';
  static const _toggleOvertimeKey = 'toggle_overtime';
  static const _togglePenaltyKey = 'toggle_penalty';
  static const _toggleMoodKey = 'toggle_mood';

  static Future<Map<String, Shift>> loadShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_shiftsKey);
    if (data == null) return {};
    final raw = Map<String, dynamic>.from(jsonDecode(data));
    return raw.map((k, v) => MapEntry(k, Shift.fromJson(Map<String, dynamic>.from(v))));
  }

  static Future<void> saveShifts(Map<String, Shift> shifts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shiftsKey, jsonEncode(shifts.map((k, v) => MapEntry(k, v.toJson()))));
  }

  static Future<List<<Goal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_goalsKey);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => Goal.fromJson(e)).toList();
  }

  static Future<void> saveGoals(List<<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  static Future<<({String name, double price})> loadLegacyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return (name: prefs.getString(_goalNameKey) ?? '', price: prefs.getDouble(_goalPriceKey) ?? 0.0);
  }

  static Future<void> saveLegacyGoal(String name, double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalNameKey, name);
    await prefs.setDouble(_goalPriceKey, price);
  }

  static Future<bool> loadIsDark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkKey) ?? true;
  }

  static Future<void> saveIsDark(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, v);
  }

  static Future<bool> loadIsPlusCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_plusKey) ?? false;
  }

  static Future<void> savePlusStatus(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_plusKey, v);
  }

  static Future<int> loadPromoExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_promoKey) ?? 0;
  }

  static Future<void> savePromoExpiry(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_promoKey, ms);
  }

  static Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? '₽';
  }

  static Future<void> saveCurrency(String c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, c);
  }

  static Future<<({int percent, String period})> loadTaxSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (percent: prefs.getInt(_taxPercentKey) ?? 6, period: prefs.getString(_taxPeriodKey) ?? 'month');
  }

  static Future<void> saveTaxSettings(int percent, String period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_taxPercentKey, percent);
    await prefs.setString(_taxPeriodKey, period);
  }

  static Future<Map<String, bool>> loadToggles() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'bonus': prefs.getBool(_toggleBonusKey) ?? true,
      'overtime': prefs.getBool(_toggleOvertimeKey) ?? true,
      'penalty': prefs.getBool(_togglePenaltyKey) ?? true,
      'mood': prefs.getBool(_toggleMoodKey) ?? true,
    };
  }

  static Future<void> saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('toggle_$key', value);
  }
}
