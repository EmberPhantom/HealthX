import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../screens/home_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/tracker_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  // 5 tabs total:
  //   0 – Home
  //   1 – Menu
  //   2 – Tracker
  //   3 – Cart
  //   4 – Profile
  static const _screens = [
    HomeScreen(),
    MenuScreen(),
    TrackerScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    const int navItemCount = 5;
    final int safeIndex = provider.currentTabIndex.clamp(0, navItemCount - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final handled = context.read<AppProvider>().popTab();
        if (!handled) {
          if (safeIndex == 0) {
            final now = DateTime.now();
            if (_lastBackPress == null ||
                now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
              _lastBackPress = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // Exit app properly (no black screen)
              SystemNavigator.pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: AppShell._screens,
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}