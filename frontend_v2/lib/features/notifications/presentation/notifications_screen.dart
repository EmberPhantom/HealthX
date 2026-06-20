import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../../../core/models/notification_models.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifications = state.notifications;
    final hasUnread = state.unreadCount > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllRead();
              },
              child: Text(
                'Mark all',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
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
      body: state.isLoading && notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () async {
                await ref.read(notificationProvider.notifier).fetchNotifications();
              },
              child: notifications.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _AnimatedNotificationTile(
                          index: index,
                          notification: notification,
                          onDismissed: () {
                            ref
                                .read(notificationProvider.notifier)
                                .deleteNotification(notification.id);
                          },
                          onTap: () {
                            if (!notification.isRead) {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markAsRead(notification.id);
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIconsRegular.bellSlash,
                size: 48,
                color: AppColors.neutral.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when there are updates\nabout your health and orders.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNotificationTile extends StatelessWidget {
  final int index;
  final NotificationModel notification;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const _AnimatedNotificationTile({
    required this.index,
    required this.notification,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0.0, 30.0 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            PhosphorIconsRegular.trash,
            color: AppColors.error,
            size: 24,
          ),
        ),
        onDismissed: (_) => onDismissed(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? AppColors.tertiary : const Color(0xFFFBFEEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isRead
                    ? AppColors.border.withOpacity(0.5)
                    : _categoryAccent(notification.category).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category-specific icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _categoryAccent(notification.category).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _categoryIcon(notification.category, notification.type),
                    size: 20,
                    color: _categoryAccent(notification.category),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _categoryAccent(notification.category),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            _categoryIcon(notification.category, ''),
                            size: 11,
                            color: AppColors.neutral.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _categoryLabel(notification.category),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _categoryAccent(notification.category).withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.neutral.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, h:mm a').format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _categoryAccent(String category) {
    switch (category) {
      case 'orders':
        return const Color(0xFF10B981);
      case 'appointments':
        return const Color(0xFF6366F1);
      case 'chat':
        return const Color(0xFF0EA5E9);
      case 'health':
        return const Color(0xFFEF4444);
      case 'promotions':
        return const Color(0xFFD97706);
      default:
        return AppColors.secondary;
    }
  }

  IconData _categoryIcon(String category, String type) {
    switch (category) {
      case 'orders':
        return PhosphorIconsRegular.shoppingBag;
      case 'appointments':
        return PhosphorIconsRegular.calendarCheck;
      case 'chat':
        return PhosphorIconsRegular.chatCircle;
      case 'health':
        return PhosphorIconsRegular.heartbeat;
      case 'promotions':
        return PhosphorIconsRegular.tag;
      default:
        // Fall back to type-based icon for 'general'
        switch (type) {
          case 'success':
            return PhosphorIconsRegular.checkCircle;
          case 'warning':
            return PhosphorIconsRegular.warning;
          case 'error':
            return PhosphorIconsRegular.warningCircle;
          default:
            return PhosphorIconsRegular.bell;
        }
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'orders':
        return 'Orders';
      case 'appointments':
        return 'Appointments';
      case 'chat':
        return 'Consultation';
      case 'health':
        return 'Health Alert';
      case 'promotions':
        return 'Offers';
      default:
        return 'HealthX';
    }
  }
}
