import 'package:flutter/material.dart';

import '../models/weekday.dart';
import 'meal_library_page.dart';
import 'plan_tabs_page.dart';
import 'shopping_list_page.dart';
import 'statistics_page.dart';
import 'sheets/add_meal_to_day_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final ValueNotifier<Weekday> _selectedDay = ValueNotifier<Weekday>(Weekday.mon);

  @override
  void dispose() {
    _selectedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          PlanTabsPage(selectedDay: _selectedDay),
          const StatisticsPage(),
          const MealLibraryPage(),
          const ShoppingListPage(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => AddMealToDaySheet(day: _selectedDay.value),
              ),
              icon: const Icon(Icons.add),
              label: const Text("Mahlzeit hinzufügen"),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: Image.asset("assets/icon/nav_plan.png", width: 24, height: 24),
            selectedIcon:
                Image.asset("assets/icon/nav_plan.png", width: 24, height: 24),
            label: "Wochenplan",
          ),
          const NavigationDestination(
            icon: ImageIcon(
              AssetImage("assets/icon/nav_stats.png"),
              color: Color.fromARGB(255, 46, 45, 45),
            ),
            selectedIcon: ImageIcon(
              AssetImage("assets/icon/nav_stats.png"),
              color: Color.fromARGB(255, 46, 45, 45),
            ),
            label: "Statistik",
          ),
          NavigationDestination(
            icon:
                Image.asset("assets/icon/nav_library.png", width: 24, height: 24),
            selectedIcon: Image.asset("assets/icon/nav_library.png",
                width: 24, height: 24),
            label: "Bibliothek",
          ),
          NavigationDestination(
            icon: Image.asset("assets/icon/nav_shop.png", width: 24, height: 24),
            selectedIcon:
                Image.asset("assets/icon/nav_shop.png", width: 24, height: 24),
            label: "Einkaufsliste",
          ),
        ],
      ),
    );
  }
}