import 'meal_category.dart';

class MealTemplate {
  final String id;
  final String name;
  final MealCategory category;

  final String? description;

  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  MealTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "category": category.name,
        "description": description,
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
      };

  factory MealTemplate.fromJson(Map<String, dynamic> json) {
    final descRaw = json["description"] as String?;
    final desc =
        (descRaw == null || descRaw.trim().isEmpty) ? null : descRaw.trim();

    return MealTemplate(
      id: json["id"] as String,
      name: json["name"] as String,
      category: mealCategoryFromJson(json["category"]),
      description: desc,
      calories: (json["calories"] as num?)?.toInt(),
      protein: (json["protein"] as num?)?.toDouble(),
      carbs: (json["carbs"] as num?)?.toDouble(),
      fat: (json["fat"] as num?)?.toDouble(),
    );
  }
}