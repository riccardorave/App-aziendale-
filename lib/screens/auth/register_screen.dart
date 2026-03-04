import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _department = '';
  bool _obscure = true;

  final _departments = [
    'Sviluppo',
    'Marketing',
    'Commerciale',
    'Amministrazione',
    'HR',
    'IT'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String pw) {
    if (pw.length < 8) return 'Minimo 8 caratteri';
    if (!RegExp(r'[A-Z]').hasMatch(pw)) return 'Almeno una lettera maiuscola';
    if (!RegExp(r'[0-9]').hasMatch(pw)) return 'Almeno un numero';
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(pw))
      return 'Almeno un simbolo (es. @, ., #)';
    return null;
  }

  Future<void> _register() async {
    final pwError = _validatePassword(_passwordCtrl.text);
    if (pwError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(pwError), backgroundColor: const Color(0xFFF87171)));
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _department,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B7CFA), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('BookSpace',
                      style: TextStyle(
                          color: Color(0xFFE8EAF0),
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Crea account',
                  style: TextStyle(
                      color: Color(0xFFE8EAF0),
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Registrati per iniziare',
                  style: TextStyle(color: Color(0xFF7B82A0), fontSize: 14)),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (auth.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x26F87171),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x4DF87171)),
                          ),
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: Color(0xFFF87171), fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildLabel('Nome completo'),
                      const SizedBox(height: 6),
                      _buildTextField(
                          controller: _nameCtrl, hint: 'Mario Rossi'),
                      const SizedBox(height: 16),
                      _buildLabel('Email'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailCtrl,
                        hint: 'nome@azienda.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Dipartimento'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _department.isEmpty ? null : _department,
                        dropdownColor: const Color(0xFF1C2030),
                        style: const TextStyle(
                            color: Color(0xFFE8EAF0), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Seleziona...',
                          hintStyle: const TextStyle(color: Color(0xFF4A5070)),
                          filled: true,
                          fillColor: const Color(0xFF1C2030),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.07)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                        ),
                        items: _departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _department = v ?? ''),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Password'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordCtrl,
                        hint: 'Min 8 car., 1 maiuscola, 1 numero, 1 simbolo',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF7B82A0),
                              size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7CFA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Crea account',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hai già un account?',
                              style: TextStyle(
                                  color: Color(0xFF7B82A0), fontSize: 14)),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Accedi',
                                style: TextStyle(
                                    color: Color(0xFF5B7CFA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
          color: Color(0xFF7B82A0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A5070)),
        filled: true,
        fillColor: const Color(0xFF1C2030),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF12152A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5B7CFA)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }
}
