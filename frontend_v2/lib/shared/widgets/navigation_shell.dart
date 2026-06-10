import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'profile_drawer.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/tracker/presentation/tracker_screen.dart';
import '../../features/consults/presentation/consults_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';

class NavigationShell extends StatefulWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late final PageController _pageController;
  bool _isAnimatingToPage = false;
  ScrollPhysics _physics = const BouncingScrollPhysics();

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tracker')) return 1;
    if (location.startsWith('/consults')) return 2;
    if (location.startsWith('/shop')) return 3;
    return 0; // Default to /home
  }

  @override
  void initState() {
    super.initState();
    // Initialize PageController with current route page index
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPage = _getSelectedIndex(context);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(initialPage);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pageController.hasClients) {
      final selectedIndex = _getSelectedIndex(context);
      if (_pageController.page?.round() != selectedIndex && !_isAnimatingToPage) {
        _pageController.jumpToPage(selectedIndex);
      }
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentSelectedIndex = _getSelectedIndex(context);
    if (index == currentSelectedIndex) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isAnimatingToPage = true;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isAnimatingToPage = false;
        });
      }
    });

    _navigateToIndex(index, context);
  }

  void _navigateToIndex(int index, BuildContext context) {
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
      body: Listener(
        onPointerDown: (event) {
          // If on Home page and dragging from the left edge (dx < 50.0)
          if (_getSelectedIndex(context) == 0 && event.position.dx < 50.0) {
            setState(() {
              _physics = const NeverScrollableScrollPhysics();
            });
          } else {
            if (_physics is NeverScrollableScrollPhysics) {
              setState(() {
                _physics = const BouncingScrollPhysics();
              });
            }
          }
        },
        onPointerUp: (event) {
          if (_physics is NeverScrollableScrollPhysics) {
            setState(() {
              _physics = const BouncingScrollPhysics();
            });
          }
        },
        child: PageView(
          controller: _pageController,
          physics: _physics,
          onPageChanged: (index) {
            if (!_isAnimatingToPage) {
              final currentSelectedIndex = _getSelectedIndex(context);
              if (index != currentSelectedIndex) {
                HapticFeedback.lightImpact();
                _navigateToIndex(index, context);
              }
            }
          },
          children: const [
            HomeScreen(),
            TrackerScreen(),
            ConsultsScreen(),
            ShopScreen(),
          ],
        ),
      ),
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
