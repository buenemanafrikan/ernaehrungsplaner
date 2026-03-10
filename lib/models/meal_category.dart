import 'package:flutter/material.dart';

enum MealCategory { breakfast, lunch, dinner, snack }

extension MealCategoryX on MealCategory {
  String get label {
    switch (this) {
      case MealCategory.breakfast:
        return "Frühstück";
      case MealCategory.lunch:
        return "Mittag";
      case MealCategory.dinner:
        return "Abend";
      case MealCategory.snack:
        return "Snack";
    }
  }

  IconData get icon {
    switch (this) {
      case MealCategory.breakfast:
        return Icons.free_breakfast_outlined;
      case MealCategory.lunch:
        return Icons.lunch_dining_outlined;
      case MealCategory.dinner:
        return Icons.dinner_dining_outlined;
      case MealCategory.snack:
        return Icons.cookie_outlined;
    }
  }

  String get assetIcon {
    switch (this) {
      case MealCategory.breakfast:
        return "assets/icon/breakfast.png";
      case MealCategory.lunch:
        return "assets/icon/lunch.png";
      case MealCategory.dinner:
        return "assets/icon/dinner.png";
      case MealCategory.snack:
        return "assets/icon/snack.png";
    }
  }
}

// ersetzte Version von deinem _categoryFromJson, damit es importierbar ist
MealCategory mealCategoryFromJson(dynamic v) {
  final s = v is String ? v : null;
  if (s == null) return MealCategory.lunch;

  return MealCategory.values.firstWhere(
    (c) => c.name == s,
    orElse: () => MealCategory.lunch,
  );
}