import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amministrazione',
            style: TextStyle(
                color: Color(0xFFE8EAF0), fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: TabController(
              length: 4, vsync: Scaffold.of(context) as TickerProvider),
          onTap: (i) => setState(() => _tabIndex = i),
          tabs: const [
            Tab(text: 'Prenotazioni'),
            Tab(text: 'Risorse'),
            Tab(text: 'Utenti'),
            Tab(text: 'Log'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _AdminBookingsTab(api: _api),
          _AdminResourcesTab(api: _api),
          _AdminUsersTab(api: _api),
          _AdminLogsTab(api: _api),
        ],
      ),
    );
  }
}

// ── PRENOTAZIONI ──
class _AdminBookingsTab extends StatefulWidget {
  final ApiService api;
  const _AdminBookingsTab({required this.api});
  @override
  State<_AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<_AdminBookingsTab> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.getBookings(upcoming: true);
      setState(() {
        _bookings = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await widget.api.cancelBooking(id);
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
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B7CFA)));
    if (_bookings.isEmpty)
      return const Center(
          child: Text('Nessuna prenotazione futura',
              style: TextStyle(color: Color(0xFF7B82A0))));
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF5B7CFA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) {
          final b = _bookings[i];
          final start = DateTime.parse(b['start_time']);
          final end = DateTime.parse(b['end_time']);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['title'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFFE8EAF0),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(b['user_name'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF5B7CFA), fontSize: 12)),
                      Text(
                          '${b['resource_name']} · ${DateFormat('dd/MM HH:mm').format(start)}–${DateFormat('HH:mm').format(end)}',
                          style: const TextStyle(
                              color: Color(0xFF7B82A0), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFF87171)),
                  onPressed: () => _cancel(b['id'].toString()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── RISORSE ──
class _AdminResourcesTab extends StatefulWidget {
  final ApiService api;
  const _AdminResourcesTab({required this.api});
  @override
  State<_AdminResourcesTab> createState() => _AdminResourcesTabState();
}

class _AdminResourcesTabState extends State<_AdminResourcesTab> {
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
      final res = await widget.api.getResources();
      setState(() {
        _resources = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String id, bool activate) async {
    try {
      await widget.api.toggleResource(id, activate);
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFF87171)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B7CFA)));
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF5B7CFA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        itemBuilder: (_, i) {
          final r = _resources[i];
          final isActive = r['is_active'] == true;
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFFE8EAF0),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(r['location'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF7B82A0), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF34D399).withOpacity(0.15)
                        : const Color(0xFFF87171).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(isActive ? 'Attiva' : 'Disattiva',
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _toggle(r['id'].toString(), !isActive),
                  child: Text(isActive ? 'Disattiva' : 'Riattiva',
                      style: const TextStyle(
                          color: Color(0xFF5B7CFA), fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── UTENTI ──
class _AdminUsersTab extends StatefulWidget {
  final ApiService api;
  const _AdminUsersTab({required this.api});
  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.getUsers();
      setState(() {
        _users = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleRole(String id, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'employee' : 'admin';
    try {
      await widget.api.updateUserRole(id, newRole);
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFF87171)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B7CFA)));
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF5B7CFA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i];
          final isAdmin = u['role'] == 'admin';
          final avatarColor = Color(int.parse(
              (u['avatar_color'] ?? '#5B7CFA').replaceFirst('#', '0xFF')));
          final initials = (u['name'] ?? 'U')
              .split(' ')
              .map((p) => p.isNotEmpty ? p[0] : '')
              .join()
              .toUpperCase();
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
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 20,
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u['name'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFFE8EAF0),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(u['email'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF7B82A0), fontSize: 12)),
                      Text(u['department'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF7B82A0), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color(0xFF5B7CFA).withOpacity(0.15)
                            : const Color(0xFF34D399).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(isAdmin ? '⚡ Admin' : '👤 Utente',
                          style: TextStyle(
                              color: isAdmin
                                  ? const Color(0xFF5B7CFA)
                                  : const Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () =>
                          _toggleRole(u['id'].toString(), u['role']),
                      child: Text(isAdmin ? 'Rimuovi admin' : 'Rendi admin',
                          style: const TextStyle(
                              color: Color(0xFF5B7CFA), fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── LOG ──
class _AdminLogsTab extends StatefulWidget {
  final ApiService api;
  const _AdminLogsTab({required this.api});
  @override
  State<_AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends State<_AdminLogsTab> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.getLogs();
      setState(() {
        _logs = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _actionColor(String action) {
    return {
          'BOOKING_CREATED': const Color(0xFF34D399),
          'BOOKING_CANCELLED': const Color(0xFFF87171),
          'USER_ROLE_CHANGED': const Color(0xFFFBBF24)
        }[action] ??
        const Color(0xFF7B82A0);
  }

  String _actionLabel(String action) {
    return {
          'BOOKING_CREATED': 'Prenotazione creata',
          'BOOKING_CANCELLED': 'Prenotazione cancellata',
          'USER_ROLE_CHANGED': 'Ruolo modificato'
        }[action] ??
        action;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B7CFA)));
    if (_logs.isEmpty)
      return const Center(
          child: Text('Nessuna attività registrata',
              style: TextStyle(color: Color(0xFF7B82A0))));
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF5B7CFA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (_, i) {
          final l = _logs[i];
          final color = _actionColor(l['action'] ?? '');
          final date = DateTime.parse(l['created_at']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF151820),
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(_actionLabel(l['action'] ?? ''),
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(DateFormat('dd/MM HH:mm').format(date),
                        style: const TextStyle(
                            color: Color(0xFF7B82A0), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l['user_name'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFFE8EAF0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(l['details'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
