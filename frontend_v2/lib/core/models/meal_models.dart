import 'package:equatable/equatable.dart';

class MealLog extends Equatable {
  final String id;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final String foodName;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final String? imageUrl;
  final List<String> ingredients;
  final DateTime loggedAt;

  const MealLog({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.imageUrl,
    required this.ingredients,
    required this.loggedAt,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['_id'] ?? json['id'] ?? '',
      mealType: json['mealType'] ?? '',
      foodName: json['foodName'] ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt'])?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealType': mealType,
    'foodName': foodName,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'imageUrl': imageUrl,
    'ingredients': ingredients,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, mealType, foodName, calories, protein, fat, carbs, imageUrl, ingredients, loggedAt];
}
