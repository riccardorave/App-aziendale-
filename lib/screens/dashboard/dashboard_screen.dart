import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  List<dynamic> _bookings = [];
  List<dynamic> _resources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getBookings(upcoming: true, my: true),
        _api.getResources(),
      ]);
      setState(() {
        _bookings = results[0];
        _resources = results[1];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buongiorno';
    if (h < 18) return 'Buon pomeriggio';
    return 'Buonasera';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final firstName = auth.user?['name']?.split(' ')[0] ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayCount = _bookings
        .where((b) => b['start_time'].toString().startsWith(today))
        .length;
    final rooms = _resources.where((r) => r['type'] == 'meeting_room').length;
    final equipment = _resources.where((r) => r['type'] == 'equipment').length;

    return SafeArea(
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_greeting, $firstName!',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8EAF0))),
              Text(DateFormat('EEEE d MMMM', 'it_IT').format(DateTime.now()),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF7B82A0))),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF7B82A0)),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5B7CFA)))
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF5B7CFA),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _statCard('Oggi', todayCount.toString(), Icons.today,
                              const Color(0xFF5B7CFA)),
                          _statCard('Prossime', _bookings.length.toString(),
                              Icons.upcoming, const Color(0xFF34D399)),
                          _statCard('Sale', rooms.toString(),
                              Icons.meeting_room, const Color(0xFFFBBF24)),
                          _statCard('Attrezzature', equipment.toString(),
                              Icons.devices, const Color(0xFFA78BFA)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Prossime prenotazioni',
                          style: TextStyle(
                              color: Color(0xFFE8EAF0),
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (_bookings.isEmpty)
                        _emptyState()
                      else
                        ..._bookings.take(5).map((b) => _bookingCard(b)),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNewBookingDialog(context),
          backgroundColor: const Color(0xFF5B7CFA),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 22, fontWeight: FontWeight.w700)),
              Text(label,
                  style:
                      const TextStyle(color: Color(0xFF7B82A0), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final start = DateTime.parse(b['start_time']);
    final end = DateTime.parse(b['end_time']);
    final isPast = end.isBefore(DateTime.now());
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
            width: 48,
            height: 48,
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
                        fontSize: 18,
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
                Text(b['title'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFFE8EAF0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    '${b['resource_name']} · ${DateFormat('HH:mm').format(start)}–${DateFormat('HH:mm').format(end)}',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 12)),
              ],
            ),
          ),
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
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF7B82A0), size: 48),
          SizedBox(height: 12),
          Text('Nessuna prenotazione futura',
              style: TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Prenota una sala o risorsa',
              style: TextStyle(color: Color(0xFF7B82A0), fontSize: 14)),
        ],
      ),
    );
  }

  void _showNewBookingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151820),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NewBookingSheet(),
    );
  }
}

class _NewBookingSheet extends StatefulWidget {
  const _NewBookingSheet();

  @override
  State<_NewBookingSheet> createState() => _NewBookingSheetState();
}

class _NewBookingSheetState extends State<_NewBookingSheet> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  List<dynamic> _resources = [];
  String? _selectedResource;
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _recurring = false;
  int _weeks = 2;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    final res = await _api.getResources();
    setState(() => _resources = res);
  }

  Future<void> _submit() async {
    if (_selectedResource == null || _titleCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final dateStr = _date.toIso8601String().split('T')[0];
      final startStr =
          '$dateStr T${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '$dateStr T${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}:00';
      await _api.createBooking(
        resourceId: _selectedResource!,
        title: _titleCtrl.text,
        startTime: startStr.replaceAll(' ', ''),
        endTime: endStr.replaceAll(' ', ''),
        recurring: _recurring,
        weeks: _weeks,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Prenotazione confermata! 🎉'),
            backgroundColor: Color(0xFF34D399)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFF87171)));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nuova prenotazione',
                style: TextStyle(
                    color: Color(0xFFE8EAF0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedResource,
              dropdownColor: const Color(0xFF1C2030),
              style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
              decoration: _inputDecoration('Risorsa'),
              hint: const Text('Seleziona risorsa...',
                  style: TextStyle(color: Color(0xFF4A5070))),
              items: _resources
                  .map((r) => DropdownMenuItem(
                        value: r['id'].toString(),
                        child: Text(r['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedResource = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Color(0xFFE8EAF0)),
              decoration: _inputDecoration('Titolo prenotazione'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data',
                  style: TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_date),
                  style: const TextStyle(color: Color(0xFFE8EAF0))),
              trailing:
                  const Icon(Icons.calendar_today, color: Color(0xFF5B7CFA)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inizio',
                        style:
                            TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
                    subtitle: Text(_start.format(context),
                        style: const TextStyle(color: Color(0xFFE8EAF0))),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _start);
                      if (t != null) setState(() => _start = t);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fine',
                        style:
                            TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
                    subtitle: Text(_end.format(context),
                        style: const TextStyle(color: Color(0xFFE8EAF0))),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _end);
                      if (t != null) setState(() => _end = t);
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ripeti ogni settimana',
                  style: TextStyle(color: Color(0xFFE8EAF0), fontSize: 14)),
              value: _recurring,
              activeColor: const Color(0xFF5B7CFA),
              onChanged: (v) => setState(() => _recurring = v),
            ),
            if (_recurring) ...[
              const Text('Numero settimane',
                  style: TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
              Slider(
                value: _weeks.toDouble(),
                min: 2,
                max: 4,
                divisions: 2,
                activeColor: const Color(0xFF5B7CFA),
                label: '$_weeks settimane',
                onChanged: (v) => setState(() => _weeks = v.toInt()),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7CFA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Conferma prenotazione',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF7B82A0)),
      filled: true,
      fillColor: const Color(0xFF1C2030),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF5B7CFA)),
      ),
    );
  }
}
