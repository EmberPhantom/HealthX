import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'primary_button.dart';

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
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
      ),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        color: AppColors.neutral,
        size: 18,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final displayName = user?.name ?? 'Guest User';
    final displayEmail = user?.email ?? '';
    final avatarUrl = user?.avatarUrl ?? 'https://api.dicebear.com/7.x/bottts/png?seed=HealthX1';

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                          image: DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(
                          PhosphorIconsFill.pencilSimple,
                          size: 14,
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
                              ),
                        ),
                        if (displayEmail.isNotEmpty)
                          Text(
                            displayEmail,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawer Menu Items
            Expanded(
              child: Container(
                color: AppColors.tertiary,
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      context: context,
                      icon: PhosphorIconsRegular.receipt,
                      title: 'My Orders',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.background, height: 1, thickness: 1),
                    _buildDrawerItem(
                      context: context,
                      icon: PhosphorIconsRegular.mapPin,
                      title: 'Addresses',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.background, height: 1, thickness: 1),
                    _buildDrawerItem(
                      context: context,
                      icon: PhosphorIconsRegular.gift,
                      title: 'Rewards',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.background, height: 1, thickness: 1),
                    _buildDrawerItem(
                      context: context,
                      icon: PhosphorIconsRegular.gear,
                      title: 'Settings',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.background, height: 1, thickness: 1),
                    _buildDrawerItem(
                      context: context,
                      icon: PhosphorIconsRegular.question,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.background, height: 1, thickness: 1),
                  ],
                ),
              ),
            ),
            
            // Footer Links
            Container(
              color: AppColors.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.neutral, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.fileText, color: AppColors.neutral, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'T&C',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'LOGOUT',
                    isOutlined: true,
                    icon: const Icon(PhosphorIconsRegular.signOut, color: AppColors.secondary),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
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
