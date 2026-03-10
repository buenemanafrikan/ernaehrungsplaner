import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/planner_controller.dart';
import '../models/meal_category.dart';
import '../models/meal_template.dart';
import 'sheets/create_meal_template_sheet.dart';
import 'sheets/edit_meal_template_sheet.dart';

class MealLibraryPage extends StatefulWidget {
  const MealLibraryPage({super.key});

  @override
  State<MealLibraryPage> createState() => _MealLibraryPageState();
}

class _MealLibraryPageState extends State<MealLibraryPage> {
  final _search = TextEditingController();
  MealCategory? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createNewTemplate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreateMealTemplateSheet(
          onCreated: (m) async {
            await context.read<PlannerController>().addMealToLibrary(m);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final all = planner.mealLibrary.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final q = _search.text.trim().toLowerCase();
    final filtered = all.where((m) {
      final matchesQ = q.isEmpty || m.name.toLowerCase().contains(q);
      final matchesCat = _filter == null || m.category == _filter;
      return matchesQ && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mahlzeiten-Bibliothek"),
        actions: [
          IconButton(
            tooltip: "Neue Vorlage",
            icon: const Icon(Icons.add),
            onPressed: () => _createNewTemplate(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(labelText: "Suche", prefixIcon: Icon(Icons.search)),
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
                  child: Row(
                    children: [
                      ImageIcon(AssetImage(c.assetIcon), size: 18),
                      const SizedBox(width: 8),
                      Text(c.label),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text("Keine Vorlagen gefunden.")),
            )
          else
            for (final m in filtered) ...[
              Card(
                child: ListTile(
                  leading: ImageIcon(AssetImage(m.category.assetIcon), size: 24),
                  title: Text(m.name),
                  subtitle: _subtitle(m),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => EditMealTemplateSheet(existing: m),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
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