import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final loggedIn = await auth.tryAutoLogin();
    if (!mounted) return;
    context.go(loggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B7CFA), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.calendar_today,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'BookSpace',
              style: TextStyle(
                color: Color(0xFFE8EAF0),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prenotazioni aziendali',
              style: TextStyle(color: Color(0xFF7B82A0), fontSize: 14),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFF5B7CFA),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
