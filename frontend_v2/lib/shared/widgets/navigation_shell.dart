import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'profile_drawer.dart';
import '../../features/notifications/providers/notification_provider.dart';

class NavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      drawer: const ProfileDrawer(),
      drawerEdgeDragWidth: 50.0,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                PhosphorIconsRegular.list,
                color: AppColors.secondary,
                size: 26,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(context).openDrawer();
              },
            );
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
          Consumer(
            builder: (context, ref, child) {
              final notifications = ref.watch(notificationProvider).notifications;
              final unreadCount = notifications.where((n) => !n.isRead).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      PhosphorIconsRegular.bell,
                      color: AppColors.secondary,
                      size: 26,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
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
