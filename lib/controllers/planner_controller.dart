import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/cloud_planner_repository.dart';
import '../data/planner_repository_local.dart';
import '../models/goals.dart';
import '../models/meal_template.dart';
import '../models/planner_data.dart';
import '../models/shopping_item.dart';
import '../models/weekday.dart';
import '../models/week_plan.dart';

class PlannerController extends ChangeNotifier {
  final PlannerRepository localRepo;
  PlannerData _data;

  PlannerController({required this.localRepo, required PlannerData initial})
      : _data = initial;

  CloudPlannerRepository? _cloud;
  String? _cloudUid;
  StreamSubscription<PlannerData?>? _cloudSub;
  Timer? _cloudDebounce;
  bool _applyingRemote = false;
  String? _lastSyncedJson;

  List<WeekPlan> get plans => List.unmodifiable(_data.plans);
  Map<String, MealTemplate> get mealLibrary => Map.unmodifiable(_data.meals);

  WeekPlan get currentPlan => _data.plans.firstWhere(
        (p) => p.id == _data.selectedPlanId,
        orElse: () => _data.plans.first,
      );

  String get currentPlanId => currentPlan.id;

  Future<void> attachCloudSync({
    required String uid,
    required CloudPlannerRepository cloud,
  }) async {
    if (_cloudUid == uid && identical(_cloud, cloud)) return;

    await detachCloudSync();

    _cloud = cloud;
    _cloudUid = uid;

    final remote = await cloud.load(uid);
    if (remote != null) {
      await _applyRemote(remote);
    } else {
      await _pushToCloud();
    }

    _cloudSub = cloud.watch(uid).listen((remoteLive) async {
      if (remoteLive == null) return;
      await _applyRemote(remoteLive);
    });
  }

  Future<void> detachCloudSync() async {
    _cloudDebounce?.cancel();
    _cloudDebounce = null;

    await _cloudSub?.cancel();
    _cloudSub = null;

    _cloud = null;
    _cloudUid = null;
  }

  Future<void> _applyRemote(PlannerData remote) async {
    final remoteJson = jsonEncode(remote.toJson());
    final localJson = jsonEncode(_data.toJson());

    if (remoteJson == localJson) {
      _lastSyncedJson = remoteJson;
      return;
    }

    _applyingRemote = true;
    _data = remote;
    _lastSyncedJson = remoteJson;
    notifyListeners();

    await localRepo.save(_data);

    _applyingRemote = false;
  }

  Future<void> _persist() async {
    await localRepo.save(_data);

    if (_cloud != null && _cloudUid != null && !_applyingRemote) {
      final currentJson = jsonEncode(_data.toJson());
      if (currentJson == _lastSyncedJson) return;

      _cloudDebounce?.cancel();
      _cloudDebounce = Timer(const Duration(milliseconds: 600), () async {
        await _pushToCloud();
      });
    }
  }

  Future<void> _pushToCloud() async {
    final cloud = _cloud;
    final uid = _cloudUid;
    if (cloud == null || uid == null) return;

    final currentJson = jsonEncode(_data.toJson());
    await cloud.save(uid, _data);
    _lastSyncedJson = currentJson;
  }

  // ---- Shopping ----
  List<ShoppingItem> get shoppingList => List.unmodifiable(_data.shopping);

  Future<void> addShoppingItem(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final item = ShoppingItem(id: const Uuid().v4(), text: t, done: false);
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: [..._data.shopping, item],
    );
    notifyListeners();
    await _persist();
  }

  Future<void> toggleShoppingItem(String id) async {
    final updated = _data.shopping.map((s) {
      if (s.id != id) return s;
      return s.copyWith(done: !s.done);
    }).toList();

    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: updated,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteShoppingItem(String id) async {
    final updated = _data.shopping.where((s) => s.id != id).toList();
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: updated,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> clearCompletedShopping() async {
    final updated = _data.shopping.where((s) => !s.done).toList();
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: updated,
    );
    notifyListeners();
    await _persist();
  }

  // ---- Plans ----
  Future<void> setCurrentPlan(String planId) async {
    if (_data.selectedPlanId == planId) return;
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: planId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> createPlan(String name) async {
    final id = const Uuid().v4();
    final newPlan = WeekPlan.empty(
      id: id,
      name: name.trim().isEmpty ? "Neuer Plan" : name.trim(),
    );
    _data = PlannerData(
      plans: [..._data.plans, newPlan],
      selectedPlanId: id,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> duplicateCurrentPlan() async {
    final src = currentPlan;
    final id = const Uuid().v4();
    final copiedDays = <Weekday, List<String>>{
      for (final d in Weekday.values)
        d: List<String>.from(src.dayMealIds[d] ?? const []),
    };

    final copy = WeekPlan(
      id: id,
      name: "${src.name} (Kopie)",
      dayMealIds: copiedDays,
      goals: src.goals,
    );

    _data = PlannerData(
      plans: [..._data.plans, copy],
      selectedPlanId: id,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> renameCurrentPlan(String newName) async {
    final name = newName.trim();
    if (name.isEmpty) return;

    final updated = _data.plans.map((p) {
      if (p.id != currentPlanId) return p;
      return p.copyWith(name: name);
    }).toList();

    _data = PlannerData(
      plans: updated,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateGoalsForCurrentPlan(Goals goals) async {
    final updated = _data.plans.map((p) {
      if (p.id != currentPlanId) return p;
      return p.copyWith(goals: goals);
    }).toList();

    _data = PlannerData(
      plans: updated,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCurrentPlan() async {
    if (_data.plans.length <= 1) return;
    final remaining = _data.plans.where((p) => p.id != currentPlanId).toList();
    _data = PlannerData(
      plans: remaining,
      selectedPlanId: remaining.first.id,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  // ---- Library ----
  Future<void> addMealToLibrary(MealTemplate meal) async {
    final meals = {..._data.meals}..[meal.id] = meal;
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateMealInLibrary(MealTemplate updated) async {
    if (!_data.meals.containsKey(updated.id)) return;
    final meals = {..._data.meals}..[updated.id] = updated;
    _data = PlannerData(
      plans: _data.plans,
      selectedPlanId: _data.selectedPlanId,
      meals: meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteMealFromLibrary(String mealId) async {
    if (!_data.meals.containsKey(mealId)) return;

    final meals = {..._data.meals}..remove(mealId);

    final updatedPlans = _data.plans.map((p) {
      final newDays = <Weekday, List<String>>{};
      for (final d in Weekday.values) {
        final list = List<String>.from(p.dayMealIds[d] ?? const []);
        list.removeWhere((id) => id == mealId);
        newDays[d] = list;
      }
      return p.copyWith(dayMealIds: newDays);
    }).toList();

    _data = PlannerData(
      plans: updatedPlans,
      selectedPlanId: _data.selectedPlanId,
      meals: meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> duplicateMeal(String mealId) async {
    final original = _data.meals[mealId];
    if (original == null) return;

    final copy = MealTemplate(
      id: const Uuid().v4(),
      name: "${original.name} (Kopie)",
      category: original.category,
      description: original.description,
      calories: original.calories,
      protein: original.protein,
      carbs: original.carbs,
      fat: original.fat,
    );
    await addMealToLibrary(copy);
  }

  // ---- Plan day operations ----
  List<String> mealIdsForDay(Weekday day) =>
      List.unmodifiable(currentPlan.dayMealIds[day] ?? const []);

  List<MealTemplate> mealsForDay(Weekday day) {
    final ids = currentPlan.dayMealIds[day] ?? const [];
    final result = <MealTemplate>[];
    for (final id in ids) {
      final m = _data.meals[id];
      if (m != null) result.add(m);
    }
    return result;
  }

  Future<void> addMealToDay(Weekday day, String mealId) async {
    if (!_data.meals.containsKey(mealId)) return;

    final updatedPlans = _data.plans.map((p) {
      if (p.id != currentPlanId) return p;

      final newDays = <Weekday, List<String>>{
        for (final d in Weekday.values)
          d: List<String>.from(p.dayMealIds[d] ?? const []),
      };
      newDays[day]!.add(mealId);
      return p.copyWith(dayMealIds: newDays);
    }).toList();

    _data = PlannerData(
      plans: updatedPlans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> removeMealFromDayByIndex(Weekday day, int index) async {
    final updatedPlans = _data.plans.map((p) {
      if (p.id != currentPlanId) return p;

      final list = List<String>.from(p.dayMealIds[day] ?? const []);
      if (index < 0 || index >= list.length) return p;
      list.removeAt(index);

      final newDays = <Weekday, List<String>>{
        for (final d in Weekday.values)
          d: (d == day)
              ? list
              : List<String>.from(p.dayMealIds[d] ?? const []),
      };
      return p.copyWith(dayMealIds: newDays);
    }).toList();

    _data = PlannerData(
      plans: updatedPlans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> setDayOrder(Weekday day, List<String> newOrder) async {
    final updatedPlans = _data.plans.map((p) {
      if (p.id != currentPlanId) return p;

      final newDays = <Weekday, List<String>>{
        for (final d in Weekday.values)
          d: List<String>.from(p.dayMealIds[d] ?? const []),
      };
      newDays[day] = List<String>.from(newOrder);

      return p.copyWith(dayMealIds: newDays);
    }).toList();

    _data = PlannerData(
      plans: updatedPlans,
      selectedPlanId: _data.selectedPlanId,
      meals: _data.meals,
      shopping: _data.shopping,
    );
    notifyListeners();
    await _persist();
  }

  // Totals
  int totalCalories(Weekday day) =>
      mealsForDay(day).fold(0, (s, m) => s + (m.calories ?? 0));
  double totalProtein(Weekday day) =>
      mealsForDay(day).fold(0.0, (s, m) => s + (m.protein ?? 0.0));
  double totalCarbs(Weekday day) =>
      mealsForDay(day).fold(0.0, (s, m) => s + (m.carbs ?? 0.0));
  double totalFat(Weekday day) =>
      mealsForDay(day).fold(0.0, (s, m) => s + (m.fat ?? 0.0));

  bool hasAnyCalories(Weekday day) =>
      mealsForDay(day).any((m) => m.calories != null);
  bool hasAnyProtein(Weekday day) =>
      mealsForDay(day).any((m) => m.protein != null);
  bool hasAnyCarbs(Weekday day) =>
      mealsForDay(day).any((m) => m.carbs != null);
  bool hasAnyFat(Weekday day) => mealsForDay(day).any((m) => m.fat != null);

  @override
  void dispose() {
    _cloudDebounce?.cancel();
    _cloudSub?.cancel();
    super.dispose();
  }
}