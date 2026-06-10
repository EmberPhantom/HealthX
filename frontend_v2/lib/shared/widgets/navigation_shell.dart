import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'profile_drawer.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tracker')) return 1;
    if (location.startsWith('/consults')) return 2;
    if (location.startsWith('/shop')) return 3;
    return 0; // Default to /home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/tracker');
        break;
      case 2:
        context.go('/consults');
        break;
      case 3:
        context.go('/shop');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _getSelectedIndex(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const ProfileDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            PhosphorIconsRegular.list,
            color: AppColors.secondary,
            size: 26,
          ),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
            children: const [
              TextSpan(text: 'HEALTH'),
              TextSpan(
                text: 'X',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.bell,
              color: AppColors.secondary,
              size: 26,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: AppColors.border,
            height: 1.0,
            thickness: 0.5,
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          backgroundColor: AppColors.tertiary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.neutral,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(PhosphorIconsRegular.house),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsFill.house, color: AppColors.secondary),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(PhosphorIconsRegular.chartLineUp),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsFill.chartLineUp, color: AppColors.secondary),
              ),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: const Icon(PhosphorIconsRegular.users),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsFill.users, color: AppColors.secondary),
              ),
              label: 'Consults',
            ),
            BottomNavigationBarItem(
              icon: const Icon(PhosphorIconsRegular.shoppingBag),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsFill.shoppingBag, color: AppColors.secondary),
              ),
              label: 'Shop',
            ),
          ],
        ),
      ),
    );
  }
}
