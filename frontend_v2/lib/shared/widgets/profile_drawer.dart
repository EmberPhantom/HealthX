import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final displayName = user?.name ?? 'Alex J.';
    final displayEmail = user?.email ?? 'alex.j@healthx.io';
    final avatarUrl = user?.avatarUrl ?? 'https://images.unsplash.com/photo-1544816155-12df9643f363?fit=crop&w=150&h=150'; // Default Panda

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
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

              // 2. Profile Section (Avatar and user details)
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary, // Lime green overlay
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          PhosphorIconsFill.pencilSimple,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
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
                              onTap: () {},
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.mapPin,
                              title: 'Addresses',
                              onTap: () {},
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.gift,
                              title: 'Rewards',
                              onTap: () {},
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.gear,
                              title: 'Settings',
                              onTap: () {},
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.question,
                              title: 'Help & Support',
                              onTap: () {},
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
                              onTap: () {},
                            ),
                            const Divider(color: Color(0xFFF5F5F5), height: 1, thickness: 1),
                            _buildDrawerItem(
                              context: context,
                              icon: PhosphorIconsRegular.fileText,
                              title: 'T&C',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Logout Button at the bottom
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
