import 'package:flutter/material.dart';
import 'dart:io';

// ─── Food Entry Model ─────────────────────────────────────────────────────────
class FoodEntry {
  final String? id;         // server-side database ID
  final String meal;        // Breakfast / Lunch / Dinner / Snack
  final String name;
  final int protein;
  final int fat;
  final int carbs;
  final int calories;
  final File? imageFile;    // actual picked/captured image
  final DateTime loggedAt;

  FoodEntry({
    this.id,
    required this.meal,
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    this.imageFile,
    required this.loggedAt,
  });
}

// ─── Daily Goal Model ─────────────────────────────────────────────────────────
class DailyGoal {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  const DailyGoal({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  // Default goal
  static const DailyGoal defaultGoal = DailyGoal(
    calories: 2000,
    protein: 100,
    fat: 65,
    carbs: 250,
  );
}

// ─── Global Singleton Store ───────────────────────────────────────────────────
class FoodLogStore extends ChangeNotifier {
  FoodLogStore._();
  static final FoodLogStore instance = FoodLogStore._();

  // Map from date-only key → list of food entries
  final Map<String, List<FoodEntry>> _entriesByDate = {};

  // Map from date-only key → user-set daily goal
  final Map<String, DailyGoal> _goalsByDate = {};

  // Pre-seed with one dummy Breakfast entry for today so the UI looks live
  FoodLogStore() {
    final today = _key(DateTime.now());
    _entriesByDate[today] = [
      FoodEntry(
        meal: 'Breakfast',
        name: 'Mixed fruit and veggie platter with nuts',
        protein: 32,
        fat: 47,
        carbs: 177,
        calories: 600,
        imageFile: null,
        loggedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Entries ──────────────────────────────────────────────────────────────────
  List<FoodEntry> entriesFor(DateTime date) =>
      List.unmodifiable(_entriesByDate[_key(date)] ?? []);

  void addEntry(FoodEntry entry) {
    final key = _key(entry.loggedAt);
    _entriesByDate.putIfAbsent(key, () => []);
    _entriesByDate[key]!.add(entry);
    notifyListeners();
  }

  void removeEntry(FoodEntry entry) {
    final key = _key(entry.loggedAt);
    _entriesByDate[key]?.remove(entry);
    notifyListeners();
  }

  // ── Goals ────────────────────────────────────────────────────────────────────
  /// Returns user-set goal for date, or the default if not set.
  DailyGoal goalFor(DateTime date) =>
      _goalsByDate[_key(date)] ?? DailyGoal.defaultGoal;

  /// Set (or update) the daily goal for today.
  void setGoal(DailyGoal goal, {DateTime? date}) {
    final key = _key(date ?? DateTime.now());
    _goalsByDate[key] = goal;
    notifyListeners();
  }

  // ── Aggregates ───────────────────────────────────────────────────────────────
  int totalCaloriesFor(DateTime date) =>
      entriesFor(date).fold(0, (s, e) => s + e.calories);

  int totalProteinFor(DateTime date) =>
      entriesFor(date).fold(0, (s, e) => s + e.protein);

  int totalFatFor(DateTime date) =>
      entriesFor(date).fold(0, (s, e) => s + e.fat);

  int totalCarbsFor(DateTime date) =>
      entriesFor(date).fold(0, (s, e) => s + e.carbs);

  int caloriesLeftFor(DateTime date) {
    final goal = goalFor(date).calories;
    final consumed = totalCaloriesFor(date);
    return (goal - consumed).clamp(0, goal);
  }
}
