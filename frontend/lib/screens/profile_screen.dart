import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/api/auth_models.dart';
import '../widgets/shared_widgets.dart';
import 'set_delivery_location_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import 'health_rewards_screen.dart';
import 'my_orders_screen.dart';
import 'favorites_screen.dart';
import '../widgets/rating_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _refW = 360;
  static const double _refH = 800;

  static const String _privacyUrl = 'https://www.healthx.world/#/privacy';
  static const String _termsUrl   = 'https://www.healthx.world/#/terms';
  static const String _refundUrl  = 'https://www.healthx.world/#/refund';

  // User's own rating — null means not yet rated (shows default 4.8)
  int? _userRating;
  String _appVersion = 'v1.7.0'; // fallback until async loads

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = 'v${info.version}');
    }
  }

  Color _ratingColor(int r) {
    const colors = [
      Color(0xFFE53935), // 1 – red
      Color(0xFFFF7043), // 2 – deep orange
      Color(0xFFFFB300), // 3 – amber
      Color(0xFF43A047), // 4 – green
      Color(0xFF00897B), // 5 – teal
    ];
    return colors[(r - 1).clamp(0, 4)];
  }

  Future<void> _handleRefresh(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _openAddressScreen(BuildContext context) async {
    final result = await Navigator.push<DeliveryAddress>(
      context,
      MaterialPageRoute(builder: (_) => const SetDeliveryLocationScreen()),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery address set to ${result.shortName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open page'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = context.watch<UserProvider>().user ??
                 context.watch<AuthProvider>().user ??
                 const UserProfile.empty();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 18 : ws * 24;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        displacement: hs * 20,
        edgeOffset: 0,
        color: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        onRefresh: () => _handleRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics()),
          child: Column(
            children: [
              _buildProfileHeader(context, user, ws, hs)
                  .animate()
                  .fadeIn(duration: 400.ms),

              Padding(
                padding: EdgeInsets.fromLTRB(hPad, hs * 20, hPad, hs * 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStats(context, provider, ws, hs)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.05, end: 0),

                    SizedBox(height: hs * 20),

                    _SectionLabel(label: 'Account', ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 160.ms),

                    SizedBox(height: hs * 8),

                    ..._buildAccountItems(context, ws, hs)
                        .asMap()
                        .entries
                        .map((e) => e.value
                        .animate()
                        .fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: 200 + e.key * 60),
                    )
                        .slideX(begin: 0.03, end: 0)),

                    SizedBox(height: hs * 16),

                    _SectionLabel(label: 'Legal', ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 520.ms),

                    SizedBox(height: hs * 8),

                    ..._buildLegalItems(context, ws, hs)
                        .asMap()
                        .entries
                        .map((e) => e.value
                        .animate()
                        .fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: 560 + e.key * 60),
                    )
                        .slideX(begin: 0.03, end: 0)),

                    SizedBox(height: hs * 20),

                    SizedBox(
                      width: double.infinity,
                      height: hs * 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.read<AppProvider>().logout();
                          context.read<AuthProvider>().logout();
                        },
                        icon: Icon(Icons.logout, size: ws * 18),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: ws * 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.red,
                          side: BorderSide(
                              color: AppTheme.red, width: ws * 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ws * 14)),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 740.ms),

                    SizedBox(height: hs * 10),

                    Center(
                      child: Text(
                        'HappyBowl $_appVersion',
                        style: TextStyle(
                            color: AppTheme.textLight, fontSize: ws * 11),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 800.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, user, double ws, double hs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + hs * 8,
        bottom: hs * 28,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius:
        BorderRadius.vertical(bottom: Radius.circular(ws * 28)),
      ),
      child: Column(
        children: [
          Container(
            width: ws * 80,
            height: ws * 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: ws * 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: ws * 12,
                  offset: Offset(0, hs * 4),
                ),
              ],
            ),
            child: ClipOval(
              child: HBNetworkImage(
                url: user.avatarUrl,
                width: ws * 80,
                height: ws * 80,
              ),
            ),
          ),
          SizedBox(height: hs * 14),
          Text(
            user.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: ws * 22,
            ),
          ),
          SizedBox(height: hs * 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: ws * 13,
            ),
          ),
          if (user.isPremium) ...[
            SizedBox(height: hs * 10),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: ws * 14, vertical: hs * 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(ws * 20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium,
                      color: AppTheme.yellow, size: ws * 16),
                  SizedBox(width: ws * 6),
                  Text(
                    'Premium Member',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: ws * 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(
      BuildContext context, AppProvider provider, double ws, double hs) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              value: '${provider.totalOrdersCount}',
              label: 'Total Orders',
              tapLabel: 'View history',
              icon: Icons.receipt_long,
              color: AppTheme.primaryGreen,
              ws: ws,
              hs: hs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
            ),
          ),
          SizedBox(width: ws * 12),
          Expanded(
            child: _StatTile(
              value: '${provider.favoritesCount}',
              label: 'Favorites',
              tapLabel: 'View all',
              icon: Icons.favorite,
              color: AppTheme.red,
              ws: ws,
              hs: hs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
          SizedBox(width: ws * 12),
          Expanded(
            child: _StatTile(
              value: '${provider.userRatingValue}',
              label: 'Rating',
              tapLabel: 'Tap to rate',
              icon: Icons.star_rounded,
              color: provider.userRatingValue >= 4.0 
                  ? AppTheme.primaryGreen 
                  : AppTheme.yellow,
              ws: ws,
              hs: hs,
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await showRatingDialog(context);
                if (result != null && mounted) {
                  await provider.setAppRating(result);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccountItems(
      BuildContext context, double ws, double hs) {
    final items = [
      _ProfileMenuItem(
        emoji: '📋',
        title: 'My Orders',
        subtitle: 'View order history',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        ),
      ),
      _ProfileMenuItem(
        emoji: '📍',
        title: 'Addresses',
        subtitle: 'Manage delivery addresses',
        onTap: () => _openAddressScreen(context),
      ),
      _ProfileMenuItem(
        emoji: '⚙️',
        title: 'Settings',
        subtitle: 'Permissions & app preferences',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      _ProfileMenuItem(
        emoji: '❓',
        title: 'Help & Support',
        subtitle: 'Chat with us or get assistance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
        ),
      ),
      _ProfileMenuItem(
        emoji: '🎁',
        title: 'Invite Friends',
        subtitle: 'Earn health rewards — 100 pts = ₹1',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthRewardsScreen()),
        ),
      ),
    ];

    return items.map((item) => _buildMenuTile(item, ws, hs)).toList();
  }

  List<Widget> _buildLegalItems(
      BuildContext context, double ws, double hs) {
    final items = [
      _ProfileMenuItem(
        emoji: '🔒',
        title: 'Privacy Policy',
        subtitle: 'How we handle your data',
        onTap: () => _launchUrl(context, _privacyUrl),
        trailingIcon: Icons.open_in_new,
      ),
      _ProfileMenuItem(
        emoji: '📜',
        title: 'Terms & Conditions',
        subtitle: 'Our terms of service',
        onTap: () => _launchUrl(context, _termsUrl),
        trailingIcon: Icons.open_in_new,
      ),
      _ProfileMenuItem(
        emoji: '💸',
        title: 'Refund Policy',
        subtitle: 'Cancellation & refund information',
        onTap: () => _launchUrl(context, _refundUrl),
        trailingIcon: Icons.open_in_new,
      ),
    ];

    return items.map((item) => _buildMenuTile(item, ws, hs)).toList();
  }

  Widget _buildMenuTile(_ProfileMenuItem item, double ws, double hs) {
    return Container(
      margin: EdgeInsets.only(bottom: hs * 8),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            item.onTap();
          },
          borderRadius:
          BorderRadius.circular(ws * AppTheme.radiusLarge),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: ws * 16, vertical: hs * 14),
            child: Row(
              children: [
                Text(item.emoji,
                    style: TextStyle(fontSize: ws * 22)),
                SizedBox(width: ws * 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: ws * 14,
                        ),
                      ),
                      SizedBox(height: hs * 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: ws * 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  item.trailingIcon ?? Icons.chevron_right,
                  color: AppTheme.textLight,
                  size: ws * 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Coming Soon!'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final double ws;
  final double hs;
  const _SectionLabel({required this.label, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: ws * 2, bottom: hs * 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textMedium,
          fontSize: ws * 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String? tapLabel;
  final IconData icon;
  final Color color;
  final double ws;
  final double hs;
  final VoidCallback? onTap;

  const _StatTile({
    required this.value,
    required this.label,
    this.tapLabel,
    required this.icon,
    required this.color,
    required this.ws,
    required this.hs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: EdgeInsets.symmetric(vertical: hs * 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: ws * 22),
          SizedBox(height: hs * 6),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              fontSize: ws * 20,
            ),
          ),
          SizedBox(height: hs * 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMedium,
              fontSize: ws * 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (tapLabel != null) ...[
            SizedBox(height: hs * 4),
            Text(
              tapLabel!,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: ws * 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
          ws * AppTheme.radiusLarge),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.07),
          child: tile,
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _ProfileMenuItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon,
  });
}