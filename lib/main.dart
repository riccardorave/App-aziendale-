import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  runApp(const BookSpaceApp());
}

class BookSpaceApp extends StatelessWidget {
  const BookSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Builder(builder: (context) {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
            GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
            GoRoute(
                path: '/register', builder: (_, __) => const RegisterScreen()),
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ],
          redirect: (context, state) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final isAuth = auth.isLoggedIn;
            final isSplash = state.matchedLocation == '/splash';
            final isLoginOrRegister = state.matchedLocation == '/login' ||
                state.matchedLocation == '/register';
            if (isSplash) return null;
            if (!isAuth && !isLoginOrRegister) return '/login';
            if (isAuth && isLoginOrRegister) return '/home';
            return null;
          },
        );
        return MaterialApp.router(
          title: 'BookSpace',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF5B7CFA),
              secondary: const Color(0xFFA78BFA),
              surface: const Color(0xFF151820),
              error: const Color(0xFFF87171),
            ),
            scaffoldBackgroundColor: const Color(0xFF0D0F14),
            fontFamily: 'DM Sans',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF151820),
              foregroundColor: Color(0xFFE8EAF0),
              elevation: 0,
            ),
          ),
          routerConfig: router,
        );
      }),
    );
  }
}
