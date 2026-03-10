import 'goals.dart';
import 'weekday.dart';

class WeekPlan {
  final String id;
  final String name;
  final Map<Weekday, List<String>> dayMealIds;
  final Goals goals;

  WeekPlan({
    required this.id,
    required this.name,
    required this.dayMealIds,
    required this.goals,
  });

  static WeekPlan empty({required String id, required String name}) {
    return WeekPlan(
      id: id,
      name: name,
      dayMealIds: {for (final d in Weekday.values) d: <String>[]},
      goals: const Goals(),
    );
  }

  WeekPlan copyWith({
    String? id,
    String? name,
    Map<Weekday, List<String>>? dayMealIds,
    Goals? goals,
  }) {
    return WeekPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      dayMealIds: dayMealIds ?? this.dayMealIds,
      goals: goals ?? this.goals,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "days": {
          for (final d in Weekday.values) d.name: dayMealIds[d] ?? <String>[],
        },
        "goals": goals.toJson(),
      };

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    final days = <Weekday, List<String>>{
      for (final d in Weekday.values) d: <String>[],
    };

    final rawDays = json["days"];
    if (rawDays is Map) {
      for (final d in Weekday.values) {
        final v = rawDays[d.name];
        if (v is List) {
          days[d] = v.whereType<String>().toList();
        }
      }
    }

    final goals = Goals.fromJson((json["goals"] is Map)
        ? Map<String, dynamic>.from(json["goals"])
        : null);

    return WeekPlan(
      id: json["id"] as String,
      name: json["name"] as String,
      dayMealIds: days,
      goals: goals,
    );
  }
}