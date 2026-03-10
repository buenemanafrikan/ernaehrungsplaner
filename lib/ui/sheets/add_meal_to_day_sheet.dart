import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/planner_controller.dart';
import '../../models/meal_category.dart';
import '../../models/meal_template.dart';
import '../../models/weekday.dart';
import 'create_meal_template_sheet.dart';
import 'edit_meal_template_sheet.dart';

class AddMealToDaySheet extends StatefulWidget {
  final Weekday day;
  const AddMealToDaySheet({super.key, required this.day});

  @override
  State<AddMealToDaySheet> createState() => _AddMealToDaySheetState();
}

class _AddMealToDaySheetState extends State<AddMealToDaySheet> {
  final _search = TextEditingController();
  MealCategory? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final allMeals = planner.mealLibrary.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final q = _search.text.trim().toLowerCase();
    final filtered = allMeals.where((m) {
      final matchesQ = q.isEmpty || m.name.toLowerCase().contains(q);
      final matchesCat = _filter == null || m.category == _filter;
      return matchesQ && matchesCat;
    }).toList();

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Text(
                  "Mahlzeit für ${widget.day.longLabel}",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const TabBar(
                  tabs: [
                    Tab(text: "Vorlagen"),
                    Tab(text: "Neu"),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                              labelText: "Suche",
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<MealCategory?>(
                            value: _filter,
                            decoration: const InputDecoration(labelText: "Kategorie (Filter)"),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("Alle")),
                              for (final c in MealCategory.values)
                                DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label),
                                ),
                            ],
                            onChanged: (v) => setState(() => _filter = v),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(child: Text("Keine passenden Vorlagen."))
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      return Card(
                                        child: ListTile(
                                          leading: ImageIcon(AssetImage(m.category.assetIcon), size: 24),
                                          title: Text(m.name),
                                          subtitle: _subtitle(m),
                                          onTap: () async {
                                            await planner.addMealToDay(widget.day, m.id);
                                            if (context.mounted) Navigator.pop(context);
                                          },
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == "edit") {
                                                await showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  useSafeArea: true,
                                                  builder: (_) => EditMealTemplateSheet(existing: m),
                                                );
                                              } else if (v == "dup") {
                                                await planner.duplicateMeal(m.id);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(value: "edit", child: Text("Bearbeiten")),
                                              PopupMenuItem(value: "dup", child: Text("Duplizieren")),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                      CreateMealTemplateSheet(
                        onCreated: (meal) async {
                          await planner.addMealToLibrary(meal);
                          await planner.addMealToDay(widget.day, meal.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subtitle(MealTemplate m) {
    final parts = <String>[];
    if (m.calories != null) parts.add("${m.calories} kcal");
    if (m.protein != null) parts.add("EW ${m.protein} g");
    if (m.carbs != null) parts.add("KH ${m.carbs} g");
    if (m.fat != null) parts.add("Fett ${m.fat} g");
    final line1 = parts.isEmpty ? "Keine Nährwerte" : parts.join(" • ");
    final desc = m.description;
    if (desc == null || desc.trim().isEmpty) return Text(line1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line1),
        const SizedBox(height: 2),
        Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}