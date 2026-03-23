import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/planner_controller.dart';
import '../models/weekday.dart';
import 'plan_tabs_page.dart' hide TotalsCard; 
import 'widgets/totals_card.dart';
import '../models/meal_category.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final plan = planner.currentPlan;
    final goals = plan.goals;

    int weekKcal = 0;
    double weekP = 0, weekC = 0, weekF = 0;

    bool anyKcal = false, anyP = false, anyC = false, anyF = false;

    final usage = <String, int>{};

    for (final d in Weekday.values) {
      weekKcal += planner.totalCalories(d);
      weekP += planner.totalProtein(d);
      weekC += planner.totalCarbs(d);
      weekF += planner.totalFat(d);

      anyKcal = anyKcal || planner.hasAnyCalories(d);
      anyP = anyP || planner.hasAnyProtein(d);
      anyC = anyC || planner.hasAnyCarbs(d);
      anyF = anyF || planner.hasAnyFat(d);

      for (final id in planner.mealIdsForDay(d)) {
        usage[id] = (usage[id] ?? 0) + 1;
      }
    }

    final top = usage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = top.take(5).toList();

    final weekGoalKcal = goals.calories == null ? null : goals.calories! * 7;
    final weekGoalP = goals.protein == null ? null : goals.protein! * 7;
    final weekGoalC = goals.carbs == null ? null : goals.carbs! * 7;
    final weekGoalF = goals.fat == null ? null : goals.fat! * 7;

    Widget progInt(String label, int value, int? goal) {
      if (goal == null) return const SizedBox.shrink();
      final p = goal <= 0 ? 0.0 : _clamp01(value / goal);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label: $value / $goal"),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: p),
          ],
        ),
      );
    }

    Widget progD(String label, double value, double? goal) {
      if (goal == null) return const SizedBox.shrink();
      final p = goal <= 0 ? 0.0 : _clamp01(value / goal);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label: ${value.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)}"),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: p),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Statistik / Übersicht")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Plan: ${plan.name}", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text("Wochensumme", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(anyKcal ? "$weekKcal kcal" : "— kcal"),
                  Text(anyP ? "EW: ${weekP.toStringAsFixed(1)} g" : "EW: —"),
                  Text(anyC ? "KH: ${weekC.toStringAsFixed(1)} g" : "KH: —"),
                  Text(anyF ? "Fett: ${weekF.toStringAsFixed(1)} g" : "Fett: —"),
                  if (!goals.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(),
                    Text("Wochensoll (Tagesziel × 7)", style: Theme.of(context).textTheme.titleSmall),
                    progInt("Kalorien", weekKcal, weekGoalKcal),
                    progD("Eiweiß (g)", weekP, weekGoalP),
                    progD("KH (g)", weekC, weekGoalC),
                    progD("Fett (g)", weekF, weekGoalF),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text("Tage", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final d in Weekday.values) ...[
            // quick + simpel: reuse aus plan_tabs_page.dart
            // ignore: prefer_const_constructors
            TotalsCard(day: d),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text("Top Mahlzeiten (häufig genutzt)", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (top5.isEmpty)
            const Text("Noch keine Mahlzeiten im Plan.")
          else
            Card(
              child: Column(
                children: [
                  for (final e in top5)
                    ListTile(
                      leading: planner.mealLibrary[e.key] == null
                          ? const Icon(Icons.restaurant_outlined)
                          : ImageIcon(
                              AssetImage(planner.mealLibrary[e.key]!.category.assetIcon),
                              size: 24,
                            ),
                      title: Text(planner.mealLibrary[e.key]?.name ?? "Unbekannt"),
                      subtitle: Text("Geplant: ${e.value}×"),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}