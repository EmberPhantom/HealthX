import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
      ),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        color: AppColors.neutral,
        size: 16,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final displayName = user?.name ?? (authState.isAuthenticated ? 'User' : 'Guest');
    final displayEmail = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      width: MediaQuery.of(context).size.width, // Full screen width as requested
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with Logo and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
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
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, color: AppColors.secondary, size: 24),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Profile Section (Avatar and user details + points badge)
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? const Icon(PhosphorIconsRegular.user, color: AppColors.neutral, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                        ),
                        if (user?.points != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsFill.trophy, color: AppColors.rewardsAccent, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.points} PTS',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Menu Options grouped in rounded cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Group 1 Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.receipt,
                              title: 'My Orders',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/shop/orders');
                              },
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.mapPin,
                              title: 'Addresses',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/shop/addresses');
                              },
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.gift,
                              title: 'Rewards',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/rewards');
                              },
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.gear,
                              title: 'Settings',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/settings');
                              },
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.question,
                              title: 'Help & Support',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/help');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Group 2 Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.shieldCheck,
                              title: 'Privacy Policy',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Privacy Policy is displayed on healthx.io')),
                                );
                              },
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.fileText,
                              title: 'T&C',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Terms & Conditions are displayed on healthx.io')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Logout Button & Version info at the bottom
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        border: Border.all(color: AppColors.secondary, width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.signOut,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LOGOUT',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '2.0.0';
                        return Text(
                          'HealthX v$version',
                          style: const TextStyle(color: AppColors.neutral, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
