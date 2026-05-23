import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/shift.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String currency = '₽';
  Map<String, bool> featureToggles = {
    'bonus': true,
    'overtime': true,
    'penalty': true,
    'mood': true,
  };
  Map<String, Shift> shifts = {};
  List<<Goal> goals = [];
  String legacyGoalName = '';
  double legacyGoalPrice = 0.0;

  Future<void> init() async {
    final isDark = await StorageService.loadIsDark();
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    currency = await StorageService.loadCurrency();
    featureToggles = await StorageService.loadToggles();
    shifts = await StorageService.loadShifts();
    goals = await StorageService.loadGoals();

    final legacy = await StorageService.loadLegacyGoal();
    legacyGoalName = legacy.name;
    legacyGoalPrice = legacy.price;

    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await StorageService.saveIsDark(isDark);
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    currency = c;
    await StorageService.saveCurrency(c);
    notifyListeners();
  }

  Future<void> setToggle(String key, bool value) async {
    featureToggles = {...featureToggles, key: value};
    await StorageService.saveToggle(key, value);
    notifyListeners();
  }

  Future<void> setShift(String dateKey, Shift shift) async {
    shifts = {...shifts, dateKey: shift};
    await StorageService.saveShifts(shifts);
    notifyListeners();
  }

  Future<void> setBatchShifts(Map<String, Shift> batch) async {
    shifts = {...shifts, ...batch};
    await StorageService.saveShifts(shifts);
    notifyListeners();
  }

  Future<void> deleteShift(String dateKey) async {
    final updated = Map<String, Shift>.from(shifts);
    updated.remove(dateKey);
    shifts = updated;
    await StorageService.saveShifts(shifts);
    notifyListeners();
  }

  Future<void> clearAllShifts() async {
    shifts = {};
    await StorageService.saveShifts(shifts);
    notifyListeners();
  }

  Future<void> setGoals(List<<Goal> newGoals) async {
    goals = newGoals;
    await StorageService.saveGoals(goals);
    notifyListeners();
  }

  Future<void> setLegacyGoal(String name, double price) async {
    legacyGoalName = name;
    legacyGoalPrice = price;
    await StorageService.saveLegacyGoal(name, price);
    notifyListeners();
  }

  void distributeIncome(Shift shift) {
    if (shift.type == 'off') return;
    final total = shift.totalIncome;
    if (total <= 0 || goals.isEmpty) return;
    final updated = goals.map((g) {
      final amount = total * (g.distributionPercent / 100.0);
      return Goal(
        id: g.id,
        name: g.name,
        targetAmount: g.targetAmount,
        currentAmount: g.currentAmount + amount,
        distributionPercent: g.distributionPercent,
      );
    }).toList();
    
    double distributed = 0;
    for (final g in updated) distributed += total * (g.distributionPercent / 100.0);
    final diff = total - distributed;
    if (diff.abs() > 0.001 && updated.isNotEmpty) {
      updated.last.currentAmount += diff;
    }

    setGoals(updated);
  }
}
