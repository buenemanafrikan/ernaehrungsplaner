class Goals {
  final int? calories; // kcal
  final double? protein; // g
  final double? carbs; // g
  final double? fat; // g

  const Goals({this.calories, this.protein, this.carbs, this.fat});

  bool get isEmpty =>
      calories == null && protein == null && carbs == null && fat == null;

  Map<String, dynamic> toJson() => {
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
      };

  factory Goals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Goals();
    return Goals(
      calories: (json["calories"] as num?)?.toInt(),
      protein: (json["protein"] as num?)?.toDouble(),
      carbs: (json["carbs"] as num?)?.toDouble(),
      fat: (json["fat"] as num?)?.toDouble(),
    );
  }
}