import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _api = ApiService();
  List<dynamic> _bookings = [];
  bool _loading = true;
  bool _upcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getBookings(upcoming: _upcomingOnly, my: true);
      setState(() {
        _bookings = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151820),
        title: const Text('Cancella prenotazione',
            style: TextStyle(color: Color(0xFFE8EAF0))),
        content: const Text(
            'Sei sicuro di voler cancellare questa prenotazione?',
            style: TextStyle(color: Color(0xFF7B82A0))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla',
                  style: TextStyle(color: Color(0xFF7B82A0)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancella',
                  style: TextStyle(color: Color(0xFFF87171)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.cancelBooking(id);
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Prenotazione cancellata'),
            backgroundColor: Color(0xFF34D399)));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFF87171)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie prenotazioni',
            style: TextStyle(
                color: Color(0xFFE8EAF0), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5B7CFA)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _filterChip('Prossime', _upcomingOnly, () {
                  setState(() => _upcomingOnly = true);
                  _load();
                }),
                const SizedBox(width: 8),
                _filterChip('Tutte', !_upcomingOnly, () {
                  setState(() => _upcomingOnly = false);
                  _load();
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B7CFA)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF5B7CFA),
                    child: _bookings.isEmpty
                        ? const Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  color: Color(0xFF7B82A0), size: 48),
                              SizedBox(height: 12),
                              Text('Nessuna prenotazione',
                                  style: TextStyle(
                                      color: Color(0xFFE8EAF0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('Le tue prenotazioni appariranno qui',
                                  style: TextStyle(
                                      color: Color(0xFF7B82A0), fontSize: 14)),
                            ],
                          ))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _bookings.length,
                            itemBuilder: (_, i) => _bookingCard(_bookings[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF5B7CFA).withOpacity(0.2)
              : const Color(0xFF1C2030),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active
                  ? const Color(0xFF5B7CFA)
                  : Colors.white.withOpacity(0.07)),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    active ? const Color(0xFF5B7CFA) : const Color(0xFF7B82A0),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final start = DateTime.parse(b['start_time']);
    final end = DateTime.parse(b['end_time']);
    final isPast = end.isBefore(DateTime.now());
    final isRecurring = b['recurrence_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7CFA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('d').format(start),
                    style: const TextStyle(
                        color: Color(0xFF5B7CFA),
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text(DateFormat('MMM', 'it_IT').format(start),
                    style: const TextStyle(
                        color: Color(0xFF5B7CFA), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(b['title'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFFE8EAF0),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isRecurring)
                      const Icon(Icons.repeat,
                          color: Color(0xFF5B7CFA), size: 14),
                  ],
                ),
                const SizedBox(height: 4),
                Text(b['resource_name'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 12)),
                Text(
                    '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast
                      ? const Color(0xFF232840)
                      : const Color(0xFF34D399).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(isPast ? 'Terminata' : 'Confermata',
                    style: TextStyle(
                        color: isPast
                            ? const Color(0xFF7B82A0)
                            : const Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
              if (!isPast) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _cancel(b['id'].toString()),
                  child: const Icon(Icons.close,
                      color: Color(0xFFF87171), size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
