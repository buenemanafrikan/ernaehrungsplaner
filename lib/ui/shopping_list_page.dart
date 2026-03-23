import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/planner_controller.dart';

class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({super.key});

  Future<void> _addItem(BuildContext context) async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Einkauf hinzufügen"),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: "z.B. Reis, Hähnchen, Eier…"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Hinzufügen")),
        ],
      ),
    );

    if (text != null && text.trim().isNotEmpty) {
      await context.read<PlannerController>().addShoppingItem(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerController>();
    final items = planner.shoppingList;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Einkaufsliste"),
        actions: [
          IconButton(
            tooltip: "Erledigte löschen",
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: items.any((e) => e.done) ? () => planner.clearCompletedShopping() : null,
          ),
          IconButton(
            tooltip: "Hinzufügen",
            icon: const Icon(Icons.add),
            onPressed: () => _addItem(context),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text("Noch nichts auf der Einkaufsliste."))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = items[i];
                return Card(
                  child: ListTile(
                    // Tippen markiert das Item als erledigt (Text wird grau/durchgestrichen)
                    onTap: () => planner.toggleShoppingItem(it.id),
                    title: Text(
                      it.text,
                      style: TextStyle(
                        decoration: it.done ? TextDecoration.lineThrough : null,
                        color: it.done ? Colors.grey : null,
                      ),
                    ),
                    // Dein eigenes Mülltonnen-Icon zum Löschen
                    trailing: IconButton(
                      tooltip: "Löschen",
                      icon: Image.asset(
                        "assets/icon/trash.png", 
                        width: 28, 
                        height: 28
                      ),
                      onPressed: () => planner.deleteShoppingItem(it.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
