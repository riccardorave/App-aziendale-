import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _api = ApiService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      final res = await _api.getCalendarBookings(
        DateFormat('yyyy-MM-dd').format(start),
        DateFormat('yyyy-MM-dd').format(end),
      );
      setState(() {
        _bookings = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getBookingsForDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return _bookings
        .where((b) => b['start_time'].toString().startsWith(dayStr))
        .toList();
  }

  Color _typeColor(String type) {
    return {
          'meeting_room': const Color(0xFF60A5FA),
          'desk': const Color(0xFF34D399),
          'equipment': const Color(0xFFFBBF24)
        }[type] ??
        const Color(0xFF5B7CFA);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBookings =
        _selectedDay != null ? _getBookingsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario',
            style: TextStyle(
                color: Color(0xFFE8EAF0), fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              _load();
            },
            eventLoader: _getBookingsForDay,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Color(0xFFE8EAF0)),
              weekendTextStyle: const TextStyle(color: Color(0xFF7B82A0)),
              selectedDecoration: const BoxDecoration(
                  color: Color(0xFF5B7CFA), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: const Color(0xFF5B7CFA).withOpacity(0.3),
                  shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: Color(0xFFE8EAF0)),
              markerDecoration: const BoxDecoration(
                  color: Color(0xFF5B7CFA), shape: BoxShape.circle),
              outsideTextStyle: const TextStyle(color: Color(0xFF4A5070)),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Color(0xFF7B82A0)),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Color(0xFF7B82A0)),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Color(0xFF7B82A0), fontSize: 12),
              weekendStyle: TextStyle(color: Color(0xFF7B82A0), fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((e) {
                      final b = e as Map<String, dynamic>;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _typeColor(b['resource_type'] ?? ''),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF1C2030)),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B7CFA)))
                : selectedBookings.isEmpty
                    ? const Center(
                        child: Text('Nessuna prenotazione in questo giorno',
                            style: TextStyle(color: Color(0xFF7B82A0))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedBookings.length,
                        itemBuilder: (_, i) {
                          final b = selectedBookings[i] as Map<String, dynamic>;
                          final start = DateTime.parse(b['start_time']);
                          final end = DateTime.parse(b['end_time']);
                          final color = _typeColor(b['resource_type'] ?? '');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151820),
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                  left: BorderSide(color: color, width: 3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(b['title'] ?? '',
                                          style: const TextStyle(
                                              color: Color(0xFFE8EAF0),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(b['resource_name'] ?? '',
                                          style: TextStyle(
                                              color: color, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                    '${DateFormat('HH:mm').format(start)}–${DateFormat('HH:mm').format(end)}',
                                    style: const TextStyle(
                                        color: Color(0xFF7B82A0),
                                        fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
