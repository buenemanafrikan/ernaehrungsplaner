import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/meal_category.dart';
import '../../models/meal_template.dart';

class CreateMealTemplateSheet extends StatefulWidget {
  final Future<void> Function(MealTemplate meal) onCreated;
  const CreateMealTemplateSheet({super.key, required this.onCreated});

  @override
  State<CreateMealTemplateSheet> createState() => _CreateMealTemplateSheetState();
}

class _CreateMealTemplateSheetState extends State<CreateMealTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();

  MealCategory _category = MealCategory.lunch;

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
    return SingleChildScrollView(
      child: Form(
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Als Vorlage speichern & einplanen"),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final desc = _desc.text.trim();
                  final meal = MealTemplate(
                    id: const Uuid().v4(),
                    name: _name.text.trim(),
                    category: _category,
                    description: desc.isEmpty ? null : desc,
                    calories: _tryParseIntNullable(_kcal.text),
                    protein: _tryParseDoubleNullable(_p.text),
                    carbs: _tryParseDoubleNullable(_c.text),
                    fat: _tryParseDoubleNullable(_f.text),
                  );

                  await widget.onCreated(meal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}