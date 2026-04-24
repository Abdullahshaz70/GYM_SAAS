import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime          focusedDay;
  final DateTime          selectedDay;
  final Set<DateTime>     presentDates;
  final ValueChanged<DateTime> onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.presentDates,
    required this.onDaySelected,
  });

  bool _isPresent(DateTime day) =>
      presentDates.contains(DateTime(day.year, day.month, day.day));

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay:  DateTime.utc(2035, 12, 31),
      focusedDay: focusedDay,
      availableGestures: AvailableGestures.none,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: Colors.white70, fontSize: 13),
        weekendTextStyle: TextStyle(color: Colors.white54, fontSize: 13),
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 13,
            fontWeight: FontWeight.w700),
        selectedDecoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        leftChevronIcon:
            Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 22),
        rightChevronIcon:
            Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 22),
        headerPadding: EdgeInsets.symmetric(vertical: 12),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
            color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
        weekendStyle: TextStyle(
            color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) =>
            _isPresent(day) ? _presentDay(day) : null,
        todayBuilder: (context, day, _) =>
            _isPresent(day) ? _presentDay(day) : null,
      ),
      onDaySelected: (selected, focused) => onDaySelected(selected),
    );
  }

  Widget _presentDay(DateTime day) => Container(
    margin: const EdgeInsets.all(5),
    decoration: const BoxDecoration(
      color: Colors.yellowAccent,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
            color: Colors.yellowAccent, blurRadius: 6, spreadRadius: -2)
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: const TextStyle(
          color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
    ),
  );
}
