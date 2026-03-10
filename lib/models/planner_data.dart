import 'meal_template.dart';
import 'shopping_item.dart';
import 'week_plan.dart';

class PlannerData {
  final List<WeekPlan> plans;
  final String selectedPlanId;
  final Map<String, MealTemplate> meals;
  final List<ShoppingItem> shopping;

  PlannerData({
    required this.plans,
    required this.selectedPlanId,
    required this.meals,
    required this.shopping,
  });

  Map<String, dynamic> toJson() => {
        "selectedPlanId": selectedPlanId,
        "plans": plans.map((p) => p.toJson()).toList(),
        "meals": meals.values.map((m) => m.toJson()).toList(),
        "shopping": shopping.map((s) => s.toJson()).toList(),
      };

  factory PlannerData.fromJson(Map<String, dynamic> json) {
    final plansRaw = json["plans"];
    final mealsRaw = json["meals"];
    final shoppingRaw = json["shopping"];

    final plans = <WeekPlan>[];
    if (plansRaw is List) {
      for (final p in plansRaw) {
        if (p is Map) plans.add(WeekPlan.fromJson(Map<String, dynamic>.from(p)));
      }
    }

    final meals = <String, MealTemplate>{};
    if (mealsRaw is List) {
      for (final m in mealsRaw) {
        if (m is Map) {
          final mt = MealTemplate.fromJson(Map<String, dynamic>.from(m));
          meals[mt.id] = mt;
        }
      }
    }

    final shopping = <ShoppingItem>[];
    if (shoppingRaw is List) {
      for (final s in shoppingRaw) {
        if (s is Map) {
          shopping.add(ShoppingItem.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    final selected = (json["selectedPlanId"] as String?) ??
        (plans.isNotEmpty ? plans.first.id : "");

    return PlannerData(
      plans: plans,
      selectedPlanId: selected,
      meals: meals,
      shopping: shopping,
    );
  }
}