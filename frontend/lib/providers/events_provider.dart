import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarEvent {
  final DateTime date;
  final String title;

  const CalendarEvent({
    required this.date,
    required this.title,
  });
}

class CalendarEventsNotifier extends StateNotifier<List<CalendarEvent>> {
  CalendarEventsNotifier() : super([
    // Add some default presentation events so the calendar is not empty initially
    CalendarEvent(
      date: DateTime.now().add(const Duration(days: 2)),
      title: "Annual day rehearsals",
    ),
    CalendarEvent(
      date: DateTime.now().add(const Duration(days: 5)),
      title: "Board review meeting",
    ),
  ]);

  void addEvent(DateTime date, String title) {
    // Standardize to date-only comparison (strip time)
    final dateOnly = DateTime(date.year, date.month, date.day);
    state = [
      ...state,
      CalendarEvent(date: dateOnly, title: title),
    ];
  }
}

final eventsProvider = StateNotifierProvider<CalendarEventsNotifier, List<CalendarEvent>>((ref) {
  return CalendarEventsNotifier();
});
