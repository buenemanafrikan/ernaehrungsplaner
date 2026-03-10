import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/planner_controller.dart';
import '../../models/weekday.dart';

class TotalsCard extends StatelessWidget {
  final Weekday day;
  const TotalsCard({super.key, required this.day});

  double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PlannerController>();
    final goals = ctrl.currentPlan.goals;

    final kcalTotal = ctrl.totalCalories(day);
    final pTotal = ctrl.totalProtein(day);
    final cTotal = ctrl.totalCarbs(day);
    final fTotal = ctrl.totalFat(day);

    final kcalText = ctrl.hasAnyCalories(day) ? "$kcalTotal kcal" : "— kcal";
    final pText =
        ctrl.hasAnyProtein(day) ? "EW: ${pTotal.toStringAsFixed(1)} g" : "EW: —";
    final cText =
        ctrl.hasAnyCarbs(day) ? "KH: ${cTotal.toStringAsFixed(1)} g" : "KH: —";
    final fText =
        ctrl.hasAnyFat(day) ? "Fett: ${fTotal.toStringAsFixed(1)} g" : "Fett: —";

    Widget goalRow({
      required String label,
      required double? goal,
      required double value,
      required String valueText,
    }) {
      if (goal == null) return const SizedBox.shrink();
      final prog = goal <= 0 ? 0.0 : _clamp01(value / goal);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label: $valueText / ${goal.toStringAsFixed(1)}"),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: prog),
          ],
        ),
      );
    }

    Widget goalRowInt({
      required String label,
      required int? goal,
      required int value,
      required String valueText,
    }) {
      if (goal == null) return const SizedBox.shrink();
      final prog = goal <= 0 ? 0.0 : _clamp01(value / goal);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label: $valueText / $goal"),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: prog),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${day.longLabel}\nGesamt",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(kcalText, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(pText),
                    Text(cText),
                    Text(fText),
                  ],
                ),
              ],
            ),
            if (!goals.isEmpty) ...[
              const SizedBox(height: 10),
              const Divider(),
              goalRowInt(
                label: "Kalorien",
                goal: goals.calories,
                value: kcalTotal,
                valueText: kcalTotal.toString(),
              ),
              goalRow(
                label: "Eiweiß (g)",
                goal: goals.protein,
                value: pTotal,
                valueText: pTotal.toStringAsFixed(1),
              ),
              goalRow(
                label: "KH (g)",
                goal: goals.carbs,
                value: cTotal,
                valueText: cTotal.toStringAsFixed(1),
              ),
              goalRow(
                label: "Fett (g)",
                goal: goals.fat,
                value: fTotal,
                valueText: fTotal.toStringAsFixed(1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}