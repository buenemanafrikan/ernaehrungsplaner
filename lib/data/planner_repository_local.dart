import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/meal_category.dart';
import '../models/meal_template.dart';
import '../models/planner_data.dart';
import '../models/shopping_item.dart';
import '../models/weekday.dart';
import '../models/week_plan.dart';
import '../models/goals.dart';

class PlannerRepository {
  static const _keyV2 = "nutrition_planner_v2";
  static const _keyV1 = "week_plan_v1";

  final SharedPreferences prefs;
  PlannerRepository(this.prefs);

  Future<PlannerData> load() async {
    final rawV2 = prefs.getString(_keyV2);
    if (rawV2 != null && rawV2.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV2) as Map<String, dynamic>;
        final data = PlannerData.fromJson(decoded);
        if (data.plans.isEmpty) return _defaultData();
        return data;
      } catch (_) {
        return _defaultData();
      }
    }

    final rawV1 = prefs.getString(_keyV1);
    if (rawV1 != null && rawV1.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV1) as Map<String, dynamic>;

        final meals = <String, MealTemplate>{};
        final planDays = {for (final d in Weekday.values) d: <String>[]};

        for (final d in Weekday.values) {
          final list = decoded[d.name];
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                final id = (m["id"] as String?) ?? const Uuid().v4();
                final name = (m["name"] as String?) ?? "Mahlzeit";
                final cat = mealCategoryFromJson(m["category"]);
                final mt = MealTemplate(
                  id: id,
                  name: name,
                  category: cat,
                  description: null,
                  calories: (m["calories"] as num?)?.toInt(),
                  protein: (m["protein"] as num?)?.toDouble(),
                  carbs: (m["carbs"] as num?)?.toDouble(),
                  fat: (m["fat"] as num?)?.toDouble(),
                );
                meals[mt.id] = mt;
                planDays[d]!.add(mt.id);
              }
            }
          }
        }

        final planId = const Uuid().v4();
        final plan = WeekPlan(
          id: planId,
          name: "Mein Plan",
          dayMealIds: planDays,
          goals: const Goals(),
        );

        final data = PlannerData(
          plans: [plan],
          selectedPlanId: planId,
          meals: meals,
          shopping: const <ShoppingItem>[],
        );
        await save(data);
        return data;
      } catch (_) {
        return _defaultData();
      }
    }

    return _defaultData();
  }

  PlannerData _defaultData() {
    final id = const Uuid().v4();
    return PlannerData(
      plans: [WeekPlan.empty(id: id, name: "Mein Plan")],
      selectedPlanId: id,
      meals: {},
      shopping: const <ShoppingItem>[],
    );
  }

  Future<void> save(PlannerData data) async {
    await prefs.setString(_keyV2, jsonEncode(data.toJson()));
  }
}