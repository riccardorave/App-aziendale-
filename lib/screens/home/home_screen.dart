import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../resources/resources_screen.dart';
import '../bookings/bookings_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return [
      const DashboardScreen(),
      const ResourcesScreen(),
      const BookingsScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
      if (auth.isAdmin) const AdminScreen(),
    ];
  }

  List<NavigationDestination> get _destinations {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return [
      const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      const NavigationDestination(
          icon: Icon(Icons.meeting_room_outlined),
          selectedIcon: Icon(Icons.meeting_room),
          label: 'Risorse'),
      const NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Prenotazioni'),
      const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Calendario'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profilo'),
      if (auth.isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: const NavigationBarThemeData(
            height: 60,
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF151820),
          indicatorColor: const Color(0xFF5B7CFA).withOpacity(0.2),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _destinations,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    ));
  }
}
