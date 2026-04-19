import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Set<DateTime> presentDates;
  final ValueChanged<DateTime> onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.presentDates,
    required this.onDaySelected,
  });

  // String _formatDate(DateTime d) {
  //   return "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
  // }
  //
  // bool _isPresent(DateTime day) => presentDates.contains(_formatDate(day));

  bool _isPresent(DateTime day) =>
    presentDates.contains(DateTime(day.year, day.month, day.day));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white), weekendTextStyle: TextStyle(color: Colors.white70)),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white)),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) => _isPresent(day) ? _presentDay(day) : null,
          todayBuilder: (context, day, _) => _isPresent(day) ? _presentDay(day) : null,
        ),
        onDaySelected: (selected, focused) => onDaySelected(selected),
      ),
    );
  }

  Widget _presentDay(DateTime day) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
          color: Colors.yellowAccent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.yellowAccent, blurRadius: 4)]
      ),
      alignment: Alignment.center,
      child: Text('${day.day}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }
}
