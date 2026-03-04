import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _api = ApiService();
  List<dynamic> _resources = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _typeFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getResources();
      setState(() {
        _resources = res;
        _filtered = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _resources.where((r) {
        final matchType = _typeFilter == 'all' || r['type'] == _typeFilter;
        final matchSearch = r['name'].toString().toLowerCase().contains(q) ||
            (r['location'] ?? '').toString().toLowerCase().contains(q);
        return matchType && matchSearch;
      }).toList();
    });
  }

  void _setFilter(String type) {
    setState(() => _typeFilter = type);
    _filter();
  }

  Color _typeColor(String type) {
    return {
          'meeting_room': const Color(0xFF60A5FA),
          'desk': const Color(0xFF34D399),
          'equipment': const Color(0xFFFBBF24)
        }[type] ??
        const Color(0xFF7B82A0);
  }

  String _typeLabel(String type) {
    return {
          'meeting_room': 'Sala riunioni',
          'desk': 'Desk',
          'equipment': 'Attrezzatura'
        }[type] ??
        type;
  }

  IconData _typeIcon(String type) {
    return {
          'meeting_room': Icons.meeting_room,
          'desk': Icons.desk,
          'equipment': Icons.devices
        }[type] ??
        Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risorse',
            style: TextStyle(
                color: Color(0xFFE8EAF0), fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Color(0xFFE8EAF0)),
              decoration: InputDecoration(
                hintText: 'Cerca risorsa...',
                hintStyle: const TextStyle(color: Color(0xFF4A5070)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7B82A0)),
                filled: true,
                fillColor: const Color(0xFF1C2030),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('all', 'Tutte'),
                const SizedBox(width: 8),
                _filterChip('meeting_room', '🏢 Sale'),
                const SizedBox(width: 8),
                _filterChip('desk', '💼 Desk'),
                const SizedBox(width: 8),
                _filterChip('equipment', '🎯 Attrezzature'),
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
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Nessuna risorsa trovata',
                                style: TextStyle(color: Color(0xFF7B82A0))))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _resourceCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String type, String label) {
    final active = _typeFilter == type;
    return GestureDetector(
      onTap: () => _setFilter(type),
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

  Widget _resourceCard(Map<String, dynamic> r) {
    final color = _typeColor(r['type'] ?? '');
    final amenities = r['amenities'] is List ? r['amenities'] as List : [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon(r['type'] ?? ''), color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(_typeLabel(r['type'] ?? ''),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              if (r['capacity'] != null)
                Text('👥 ${r['capacity']} persone',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(r['name'] ?? '',
              style: const TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          if (r['location'] != null) ...[
            const SizedBox(height: 4),
            Text('📍 ${r['location']}',
                style: const TextStyle(color: Color(0xFF7B82A0), fontSize: 13)),
          ],
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: amenities
                  .take(4)
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2030),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Text(a.toString(),
                            style: const TextStyle(
                                color: Color(0xFF7B82A0), fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showBookingSheet(context, r),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B7CFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Prenota',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Map<String, dynamic> resource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151820),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QuickBookSheet(resource: resource),
    );
  }
}

class _QuickBookSheet extends StatefulWidget {
  final Map<String, dynamic> resource;
  const _QuickBookSheet({required this.resource});

  @override
  State<_QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends State<_QuickBookSheet> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final dateStr = _date.toIso8601String().split('T')[0];
      final startStr =
          '$dateStr T${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '$dateStr T${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}:00';
      await _api.createBooking(
        resourceId: widget.resource['id'].toString(),
        title: _titleCtrl.text,
        startTime: startStr.replaceAll(' ', ''),
        endTime: endStr.replaceAll(' ', ''),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prenota ${widget.resource['name']}',
              style: const TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Color(0xFFE8EAF0)),
            decoration: InputDecoration(
              labelText: 'Titolo prenotazione',
              labelStyle: const TextStyle(color: Color(0xFF7B82A0)),
              filled: true,
              fillColor: const Color(0xFF1C2030),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.07))),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data',
                style: TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
            subtitle: Text('${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(color: Color(0xFFE8EAF0))),
            trailing:
                const Icon(Icons.calendar_today, color: Color(0xFF5B7CFA)),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _date = d);
            },
          ),
          Row(children: [
            Expanded(
                child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Inizio',
                  style: TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
              subtitle: Text(_start.format(context),
                  style: const TextStyle(color: Color(0xFFE8EAF0))),
              onTap: () async {
                final t =
                    await showTimePicker(context: context, initialTime: _start);
                if (t != null) setState(() => _start = t);
              },
            )),
            Expanded(
                child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fine',
                  style: TextStyle(color: Color(0xFF7B82A0), fontSize: 12)),
              subtitle: Text(_end.format(context),
                  style: const TextStyle(color: Color(0xFFE8EAF0))),
              onTap: () async {
                final t =
                    await showTimePicker(context: context, initialTime: _end);
                if (t != null) setState(() => _end = t);
              },
            )),
          ]),
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
                  : const Text('Conferma',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
