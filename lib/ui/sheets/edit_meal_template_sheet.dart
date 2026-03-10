import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/planner_controller.dart';
import '../../models/meal_category.dart';
import '../../models/meal_template.dart';

class EditMealTemplateSheet extends StatefulWidget {
  final MealTemplate existing;
  const EditMealTemplateSheet({super.key, required this.existing});

  @override
  State<EditMealTemplateSheet> createState() => _EditMealTemplateSheetState();
}

class _EditMealTemplateSheetState extends State<EditMealTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _kcal;
  late final TextEditingController _p;
  late final TextEditingController _c;
  late final TextEditingController _f;
  late MealCategory _category;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing.name);
    _desc = TextEditingController(text: widget.existing.description ?? "");
    _kcal = TextEditingController(text: widget.existing.calories?.toString() ?? "");
    _p = TextEditingController(text: widget.existing.protein?.toString() ?? "");
    _c = TextEditingController(text: widget.existing.carbs?.toString() ?? "");
    _f = TextEditingController(text: widget.existing.fat?.toString() ?? "");
    _category = widget.existing.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _kcal.dispose();
    _p.dispose();
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  double? _tryParseDoubleNullable(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(",", "."));
  }

  int? _tryParseIntNullable(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  String? _validateOptionalInt(String? v) {
    final t = (v ?? "").trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return "Bitte Zahl eingeben";
    if (n < 0) return "Nicht negativ";
    return null;
  }

  String? _validateOptionalDouble(String? v) {
    final t = (v ?? "").trim();
    if (t.isEmpty) return null;
    final n = _tryParseDoubleNullable(t);
    if (n == null) return "Bitte Zahl eingeben";
    if (n < 0) return "Nicht negativ";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerController>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Vorlage bearbeiten", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              "Änderungen wirken überall, wo diese Mahlzeit verwendet wird.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<MealCategory>(
                    value: _category,
                    decoration: const InputDecoration(labelText: "Kategorie"),
                    items: [
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
                        )
                    ],
                    onChanged: (v) => setState(() => _category = v ?? MealCategory.lunch),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: "Name *"),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Bitte Name eingeben" : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _desc,
                    decoration: const InputDecoration(
                      labelText: "Beschreibung (optional)",
                      hintText: "z.B. Rezept, Zutaten, Hinweise…",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kcal,
                    decoration: const InputDecoration(labelText: "Kalorien (kcal) (optional)"),
                    keyboardType: TextInputType.number,
                    validator: _validateOptionalInt,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _p,
                          decoration: const InputDecoration(labelText: "Eiweiß (g) (optional)"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _validateOptionalDouble,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _c,
                          decoration: const InputDecoration(labelText: "KH (g) (optional)"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _validateOptionalDouble,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _f,
                          decoration: const InputDecoration(labelText: "Fett (g) (optional)"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _validateOptionalDouble,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Speichern"),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final desc = _desc.text.trim();
                            final updated = MealTemplate(
                              id: widget.existing.id,
                              name: _name.text.trim(),
                              category: _category,
                              description: desc.isEmpty ? null : desc,
                              calories: _tryParseIntNullable(_kcal.text),
                              protein: _tryParseDoubleNullable(_p.text),
                              carbs: _tryParseDoubleNullable(_c.text),
                              fat: _tryParseDoubleNullable(_f.text),
                            );

                            await planner.updateMealInLibrary(updated);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text("Duplizieren"),
                        onPressed: () async {
                          await planner.duplicateMeal(widget.existing.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Vorlage löschen (entfernt sie aus allen Plänen)"),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Vorlage löschen?"),
                            content: Text("„${widget.existing.name}“ wirklich löschen?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Abbrechen")),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Löschen")),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await planner.deleteMealFromLibrary(widget.existing.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}