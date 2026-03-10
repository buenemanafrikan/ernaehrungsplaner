enum Weekday { mon, tue, wed, thu, fri, sat, sun }

extension WeekdayX on Weekday {
  String get shortLabel {
    switch (this) {
      case Weekday.mon:
        return "Mo";
      case Weekday.tue:
        return "Di";
      case Weekday.wed:
        return "Mi";
      case Weekday.thu:
        return "Do";
      case Weekday.fri:
        return "Fr";
      case Weekday.sat:
        return "Sa";
      case Weekday.sun:
        return "So";
    }
  }

  String get longLabel {
    switch (this) {
      case Weekday.mon:
        return "Montag";
      case Weekday.tue:
        return "Dienstag";
      case Weekday.wed:
        return "Mittwoch";
      case Weekday.thu:
        return "Donnerstag";
      case Weekday.fri:
        return "Freitag";
      case Weekday.sat:
        return "Samstag";
      case Weekday.sun:
        return "Sonntag";
    }
  }
}