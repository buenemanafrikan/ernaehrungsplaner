import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../controllers/auth_controller.dart';
import '../controllers/planner_controller.dart';
import '../models/goals.dart';
import '../models/meal_category.dart';
import '../models/meal_template.dart';
import '../models/weekday.dart';
import 'sheets/edit_meal_template_sheet.dart';
import 'widgets/totals_card.dart';

import 'package:ernaehrungsplaner/ui/plan_tabs_page.dart' hide TotalsCard;
import 'package:ernaehrungsplaner/ui/widgets/totals_card.dart';

class PlanTabsPage extends StatefulWidget {
  final ValueNotifier<Weekday> selectedDay;
  const PlanTabsPage({super.key, required this.selectedDay});

  @override
  State<PlanTabsPage> createState() => _PlanTabsPageState();
}

class _PlanTabsPageState extends State<PlanTabsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: Weekday.values.length, vsync: this);
    widget.selectedDay.value = Weekday.values[_tab.index];
    _tab.addListener(() {
      widget.selectedDay.value = Weekday.values[_tab.index];
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _showCreatePlanDialog(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Neuen Wochenplan erstellen"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: "Plan-Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Erstellen")),
        ],
      ),
    );
    if (name != null) {
      await context.read<PlannerController>().createPlan(name);
    }
  }

  Future<void> _showRenamePlanDialog(BuildContext context) async {
    final ctrl = context.read<PlannerController>();
    final c = TextEditingController(text: ctrl.currentPlan.name);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Plan umbenennen"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: "Neuer Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Speichern")),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ctrl.renameCurrentPlan(name);
    }
  }

  Future<void> _showGoalsDialog(BuildContext context) async {
    final planner = context.read<PlannerController>();
    final g = planner.currentPlan.goals;

    final kcal = TextEditingController(text: g.calories?.toString() ?? "");
    final p = TextEditingController(text: g.protein?.toString() ?? "");
    final c = TextEditingController(text: g.carbs?.toString() ?? "");
    final f = TextEditingController(text: g.fat?.toString() ?? "");

    int? parseIntOpt(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      final n = int.tryParse(t);
      if (n == null || n < 0) return null;
      return n;
    }

    double? parseDoubleOpt(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      final n = double.tryParse(t.replaceAll(",", "."));
      if (n == null || n < 0) return null;
      return n;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tagesziele (für diesen Plan)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Kalorien (kcal) – optional"),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: p,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Eiweiß (g)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: c,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "KH (g)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: f,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Fett (g)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text("Leer lassen = kein Ziel."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Speichern")),
        ],
      ),
    );

    if (saved == true) {
      await planner.updateGoalsForCurrentPlan(
        Goals(
          calories: parseIntOpt(kcal.text),
          protein: parseDoubleOpt(p.text),
          carbs: parseDoubleOpt(c.text),
          fat: parseDoubleOpt(f.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Consumer<PlannerController>(
      builder: (context, planner, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text("Plan: "),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: planner.currentPlanId,
                      isExpanded: true,
                      items: [
                        for (final p in planner.plans)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )
                      ],
                      onChanged: (id) {
                        if (id == null) return;
                        planner.setCurrentPlan(id);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Abmelden",
                icon: const Icon(Icons.logout),
                onPressed: () async => auth.signOut(),
              ),
              IconButton(
                tooltip: "Neuen Plan erstellen",
                icon: const Icon(Icons.add),
                onPressed: () => _showCreatePlanDialog(context),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == "rename") {
                    await _showRenamePlanDialog(context);
                  } else if (v == "goals") {
                    await _showGoalsDialog(context);
                  } else if (v == "duplicate") {
                    await planner.duplicateCurrentPlan();
                  } else if (v == "delete") {
                    if (planner.plans.length <= 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Du kannst den letzten Plan nicht löschen.")),
                      );
                      return;
                    }
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Plan löschen?"),
                        content: Text("„${planner.currentPlan.name}“ wirklich löschen?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen")),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Löschen")),
                        ],
                      ),
                    );
                    if (ok == true) await planner.deleteCurrentPlan();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "rename", child: Text("Plan umbenennen")),
                  PopupMenuItem(value: "goals", child: Text("Tagesziele bearbeiten")),
                  PopupMenuItem(value: "duplicate", child: Text("Plan duplizieren")),
                  PopupMenuItem(value: "delete", child: Text("Plan löschen")),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              padding: EdgeInsets.zero,
              tabs: [for (final d in Weekday.values) Tab(text: d.shortLabel)],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [for (final d in Weekday.values) DayPlanView(day: d)],
          ),
        );
      },
    );
  }
}

class DayPlanView extends StatelessWidget {
  final Weekday day;
  const DayPlanView({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final ids = planner.mealIdsForDay(day);

    final tiles = <Widget>[];
    MealCategory? lastCat;

    for (int i = 0; i < ids.length; i++) {
      final m = planner.mealLibrary[ids[i]];
      if (m == null) continue;

      if (lastCat != m.category) {
        lastCat = m.category;
        tiles.add(_CategoryHeader(cat: m.category));
        tiles.add(const SizedBox(height: 8));
      }

      tiles.add(_MealTile(day: day, indexInDay: i, meal: m));
      tiles.add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
      children: [
        TotalsCard(day: day),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text("Mahlzeiten", style: Theme.of(context).textTheme.titleMedium),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.drag_indicator),
              label: const Text("Sortieren"),
              onPressed: ids.isEmpty
                  ? null
                  : () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => ReorderDaySheet(day: day),
                      ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ids.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Noch keine Mahlzeiten für ${day.longLabel}.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        else
          ...tiles,
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final MealCategory cat;
  const _CategoryHeader({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ImageIcon(AssetImage(cat.assetIcon), size: 22),
        const SizedBox(width: 8),
        Text(cat.label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class TotalsCard extends StatelessWidget {
  final Weekday day;
  const TotalsCard({required this.day});

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
    final pText = ctrl.hasAnyProtein(day) ? "EW: ${pTotal.toStringAsFixed(1)} g" : "EW: —";
    final cText = ctrl.hasAnyCarbs(day) ? "KH: ${cTotal.toStringAsFixed(1)} g" : "KH: —";
    final fText = ctrl.hasAnyFat(day) ? "Fett: ${fTotal.toStringAsFixed(1)} g" : "Fett: —";

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

class _MealTile extends StatelessWidget {
  final Weekday day;
  final int indexInDay;
  final MealTemplate meal;

  const _MealTile({
    required this.day,
    required this.indexInDay,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerController>();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color.fromARGB(255, 189, 189, 189), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: SizedBox(
        height: 92,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/ui/meal_tile.png", fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: const Color.fromARGB(255, 245, 248, 245).withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  ImageIcon(AssetImage(meal.category.assetIcon), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(_macroLine(meal), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Image.asset("assets/icon/trash.png", width: 32, height: 32),
                    onPressed: () => planner.removeMealFromDayByIndex(day, indexInDay),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _macroLine(MealTemplate meal) {
    final parts = <String>[];
    if (meal.calories != null) parts.add("${meal.calories} kcal");
    if (meal.protein != null) parts.add("EW ${meal.protein}g");
    if (meal.carbs != null) parts.add("KH ${meal.carbs}g");
    if (meal.fat != null) parts.add("Fett ${meal.fat}g");
    return parts.isEmpty ? "Keine Nährwerte" : parts.join(" • ");
  }
}

class _ReorderEntry {
  final String keyId;
  final String mealId;
  _ReorderEntry({required this.keyId, required this.mealId});
}

class ReorderDaySheet extends StatefulWidget {
  final Weekday day;
  const ReorderDaySheet({super.key, required this.day});

  @override
  State<ReorderDaySheet> createState() => _ReorderDaySheetState();
}

class _ReorderDaySheetState extends State<ReorderDaySheet> {
  late List<_ReorderEntry> entries;

  @override
  void initState() {
    super.initState();
    final planner = context.read<PlannerController>();
    final ids = planner.mealIdsForDay(widget.day);
    entries = [
      for (final id in ids) _ReorderEntry(keyId: const Uuid().v4(), mealId: id)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Reihenfolge – ${widget.day.longLabel}",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = entries.removeAt(oldIndex);
                  entries.insert(newIndex, item);
                });
              },
              children: [
                for (final e in entries)
                  Card(
                    key: ValueKey(e.keyId),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(planner.mealLibrary[e.mealId]?.name ?? "Unbekannt"),
                      subtitle: Text(
                        planner.mealLibrary[e.mealId] == null
                            ? "Vorlage fehlt"
                            : planner.mealLibrary[e.mealId]!.category.label,
                      ),
                      trailing: planner.mealLibrary[e.mealId] == null
                          ? null
                          : ImageIcon(
                              AssetImage(planner.mealLibrary[e.mealId]!.category.assetIcon),
                              size: 22,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Speichern"),
              onPressed: () async {
                final newOrder = entries.map((e) => e.mealId).toList();
                await context.read<PlannerController>().setDayOrder(widget.day, newOrder);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}