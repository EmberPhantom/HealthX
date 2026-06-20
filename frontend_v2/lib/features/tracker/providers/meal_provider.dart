import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meal_service.dart';
import '../../../core/models/meal_models.dart';
import '../../auth/providers/auth_provider.dart';

class MealState {
  final List<MealLog> todayMeals;
  final bool isLoading;
  final String? error;

  const MealState({
    this.todayMeals = const [],
    this.isLoading = false,
    this.error,
  });

  int get todayCalories => todayMeals.fold(0, (sum, item) => sum + item.calories);
  int get todayProtein => todayMeals.fold(0, (sum, item) => sum + item.protein);
  int get todayCarbs => todayMeals.fold(0, (sum, item) => sum + item.carbs);
  int get todayFat => todayMeals.fold(0, (sum, item) => sum + item.fat);

  MealState copyWith({
    List<MealLog>? todayMeals,
    bool? isLoading,
    String? error,
  }) {
    return MealState(
      todayMeals: todayMeals ?? this.todayMeals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MealNotifier extends Notifier<MealState> {
  final MealService _service = MealService();

  @override
  MealState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchTodayMeals());
    }
    return const MealState();
  }

  Future<void> fetchTodayMeals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final meals = await _service.getMeals(DateTime.now());
      state = MealState(todayMeals: meals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns the AI inline warning string if the meal conflicts with the user's health profile.
  /// Returns null on success with no conflict, or on error.
  Future<String?> addMealLog(
    String name,
    String type,
    int calories,
    int protein,
    int carbs,
    int fat, {
    List<String> ingredients = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final mealData = {
        'foodName': name,
        'mealType': type,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'ingredients': ingredients,
      };
      final (log, warning) = await _service.logMeal(mealData);
      state = state.copyWith(
        todayMeals: [...state.todayMeals, log],
        isLoading: false,
      );
      return warning; // null if no conflict, string if there is one
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteMealLog(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteMeal(id);
      if (success) {
        state = state.copyWith(
          todayMeals: state.todayMeals.where((m) => m.id != id).toList(),
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final mealProvider = NotifierProvider<MealNotifier, MealState>(MealNotifier.new);
