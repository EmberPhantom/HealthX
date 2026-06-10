import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';

// Reference design dimensions
const double _refWidth = 360.0;
const double _refHeight = 800.0;

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentIndex = provider.currentTabIndex;

    const int navItemCount = 5;
    final int safeIndex = (currentIndex < 0)
        ? 0
        : (currentIndex >= navItemCount ? navItemCount - 1 : currentIndex);
    if (safeIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            context.read<AppProvider>().currentTabIndex != safeIndex) {
          context.read<AppProvider>().setTabIndex(safeIndex);
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final wScale = screenWidth / _refWidth;
        final hScale = screenHeight / _refHeight;

        // Reference values scaled proportionally
        final borderWidth = 0.8 * hScale;
        final blurRadius = 16.0 * wScale;
        final shadowOffsetY = -3.0 * hScale;
        final hPadding = 6.0 * wScale;
        final vPadding = 6.0 * hScale;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade100,
                width: borderWidth,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: blurRadius,
                offset: Offset(0, shadowOffsetY),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPadding,
                vertical: vPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    isActive: safeIndex == 0,
                    onTap: () => _onTabTap(context, 0),
                    wScale: wScale,
                    hScale: hScale,
                  ),
                  _NavItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Shop',
                    index: 1,
                    isActive: safeIndex == 1,
                    onTap: () => _onTabTap(context, 1),
                    wScale: wScale,
                    hScale: hScale,
                  ),
                  _NavItem(
                    icon: Icons.track_changes_rounded,
                    label: 'Tracker',
                    index: 2,
                    isActive: safeIndex == 2,
                    onTap: () => _onTabTap(context, 2),
                    wScale: wScale,
                    hScale: hScale,
                  ),
                  _NavItem(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Cart',
                    index: 3,
                    isActive: safeIndex == 3,
                    badge: provider.cartItemCount > 0 ? provider.cartItemCount : null,
                    onTap: () => _onTabTap(context, 3),
                    wScale: wScale,
                    hScale: hScale,
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    isActive: safeIndex == 4,
                    onTap: () => _onTabTap(context, 4),
                    wScale: wScale,
                    hScale: hScale,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTabTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    context.read<AppProvider>().setTabIndex(index);
  }
}

// ─────────────────────────────────────────────
// _NavItem
// ─────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;
  final double wScale;
  final double hScale;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    this.badge,
    required this.onTap,
    required this.wScale,
    required this.hScale,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  late Animation<Color?> _colorAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: AppTheme.primaryGreen,
    ).animate(
      CurvedAnimation(
          parent: _animationController!, curve: Curves.easeInOut),
    );
    if (widget.isActive) _animationController!.forward();
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController?.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController?.reverse();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) => setState(() => _isPressed = false);
  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final wScale = widget.wScale;
    final hScale = widget.hScale;

    // Proportional values from reference (360x800)
    final hPadding = 10.0 * wScale;
    final vPadding = 6.0 * hScale;
    final borderRadius = 20.0 * wScale;
    final iconSize = 24.0 * wScale;
    final labelFontSize = 13.0 * wScale;
    final labelLeftPadding = 8.0 * wScale;
    final indicatorWidth = 18.0 * wScale;
    final indicatorHeight = 2.5 * hScale;
    final indicatorBorderRadius = 1.5 * wScale;
    final indicatorBlur = 4.0 * wScale;
    final bottomSpacing = 4.0 * hScale;
    final badgeRight = -2.0 * wScale;
    final badgeTop = -2.0 * hScale;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hPadding,
          vertical: vPadding,
        ),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _colorAnimation,
                      builder: (context, child) {
                        return Icon(
                          widget.icon,
                          color: _colorAnimation.value ?? Colors.grey.shade400,
                          size: iconSize,
                        );
                      },
                    ),
                    if (widget.badge != null)
                      Positioned(
                        right: badgeRight,
                        top: badgeTop,
                        child: _AttractiveBadge(
                          badge: widget.badge!,
                          wScale: wScale,
                          hScale: hScale,
                        ),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    child: Align(
                      widthFactor: widget.isActive ? 1.0 : 0.0,
                      child: Padding(
                        padding: EdgeInsets.only(left: labelLeftPadding),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: widget.isActive ? 1.0 : 0.0,
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: widget.isActive
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade600,
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: bottomSpacing),
            if (widget.isActive)
              Container(
                width: indicatorWidth,
                height: indicatorHeight,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(indicatorBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: indicatorBlur,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _AttractiveBadge
// ─────────────────────────────────────────────
class _AttractiveBadge extends StatefulWidget {
  final int badge;
  final double wScale;
  final double hScale;

  const _AttractiveBadge({
    required this.badge,
    required this.wScale,
    required this.hScale,
  });

  @override
  State<_AttractiveBadge> createState() => _AttractiveBadgeState();
}

class _AttractiveBadgeState extends State<_AttractiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wScale = widget.wScale;
    final hScale = widget.hScale;

    final badgeSize = 16.0 * wScale;
    final borderWidth = 2.0 * wScale;
    final blurRadius = 8.0 * wScale;
    final spreadRadius = 1.0 * wScale;
    final fontSize = 7.0 * wScale;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.orange,
                  AppTheme.orange.withValues(alpha: 0.85),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.badge > 99 ? '99+' : '${widget.badge}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}