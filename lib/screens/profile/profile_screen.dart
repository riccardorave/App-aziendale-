import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  String _department = '';
  bool _savingProfile = false;
  bool _savingPassword = false;

  final _departments = [
    'Sviluppo',
    'Marketing',
    'Commerciale',
    'Amministrazione',
    'HR',
    'IT'
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameCtrl.text = user?['name'] ?? '';
    _department = user?['department'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String pw) {
    if (pw.length < 8) return 'Minimo 8 caratteri';
    if (!RegExp(r'[A-Z]').hasMatch(pw)) return 'Almeno una lettera maiuscola';
    if (!RegExp(r'[0-9]').hasMatch(pw)) return 'Almeno un numero';
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(pw)) return 'Almeno un simbolo';
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final updated =
          await _api.updateProfile(_nameCtrl.text.trim(), _department);
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateUser(updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dati aggiornati con successo!'),
            backgroundColor: Color(0xFF34D399)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFF87171)));
    }
    setState(() => _savingProfile = false);
  }

  Future<void> _savePassword() async {
    final pwError = _validatePassword(_newPwCtrl.text);
    if (pwError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(pwError), backgroundColor: const Color(0xFFF87171)));
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le password non coincidono'),
          backgroundColor: Color(0xFFF87171)));
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await _api.changePassword(_currentPwCtrl.text, _newPwCtrl.text);
      if (mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password cambiata con successo!'),
            backgroundColor: Color(0xFF34D399)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFF87171)));
    }
    setState(() => _savingPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final initials = (user?['name'] ?? 'U')
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
    final avatarColor = Color(int.parse(
        (user?['avatar_color'] ?? '#5B7CFA').replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il mio profilo',
            style: TextStyle(
                color: Color(0xFFE8EAF0), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 12),
            Text(user?['name'] ?? '',
                style: const TextStyle(
                    color: Color(0xFFE8EAF0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            Text(user?['email'] ?? '',
                style: const TextStyle(color: Color(0xFF7B82A0), fontSize: 14)),
            if (auth.isAdmin)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B7CFA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('⚡ Amministratore',
                    style: TextStyle(
                        color: Color(0xFF5B7CFA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 28),
            // Dati personali
            _sectionCard('Dati personali', [
              _buildTextField('Nome completo', _nameCtrl),
              const SizedBox(height: 12),
              _buildLabel('Email'),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2030),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Text(user?['email'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFF7B82A0), fontSize: 14)),
              ),
              const SizedBox(height: 12),
              _buildLabel('Dipartimento'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _department.isEmpty ? null : _department,
                dropdownColor: const Color(0xFF1C2030),
                style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1C2030),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.07))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _department = v ?? ''),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingProfile ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7CFA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _savingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Salva modifiche',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Sicurezza
            _sectionCard('Sicurezza', [
              _buildTextField('Password attuale', _currentPwCtrl,
                  obscure: true),
              const SizedBox(height: 12),
              _buildTextField('Nuova password', _newPwCtrl,
                  obscure: true,
                  hint: 'Min 8 car., 1 maiuscola, 1 numero, 1 simbolo'),
              const SizedBox(height: 12),
              _buildTextField('Conferma nuova password', _confirmPwCtrl,
                  obscure: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingPassword ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7CFA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _savingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Cambia password',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFE8EAF0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFF7B82A0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5));
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {bool obscure = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4A5070), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1C2030),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5B7CFA))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ],
    );
  }
}
