import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(shopProvider.notifier).fetchMoreOrders();
    }
  }

  void _confirmCancelOrder(String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (Optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final success = await ref.read(shopProvider.notifier).cancelUserOrder(
                    orderId,
                    reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Order cancelled successfully' : 'Failed to cancel order'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final orders = shopState.orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: shopState.isLoading && orders.isEmpty
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: () => ref.read(shopProvider.notifier).fetchOrders(),
              color: AppColors.primary,
              child: orders.isEmpty
                  ? ListView(
                      controller: _scrollController,
                      children: const [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: Text(
                              'No orders found.',
                              style: TextStyle(color: AppColors.neutral),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length + (shopState.hasMoreOrders ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == orders.length) {
                          return _buildLoader();
                        }
                        final order = orders[index];
                        return _buildOrderCard(context, ref, order);
                      },
                    ),
            ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    final dateStr = DateFormat('MMM d, yyyy h:mm a').format(order.createdAt);
    
    // Determine colors based on status
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';
    
    Color statusColor = Colors.orange;
    if (isDelivered) {
      statusColor = const Color(0xFF10B981);
    } else if (isCancelled) {
      statusColor = AppColors.error;
    }

    final isCancellable = order.status == 'placed' || order.status == 'confirmed';

    return GestureDetector(
      onTap: () => context.push('/shop/orders/${order.id}/track'),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header: Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ORDER #${order.id.substring(order.id.length - 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(
                text: order.status.replaceAll('_', ' ').toUpperCase(),
                dotColor: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Placed on $dateStr',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const Divider(height: 20),

          // Items List
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.name} x${item.quantity}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toInt()}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),

          // Order Pipeline Progress Indicator
          if (!isCancelled && !isDelivered) ...[
            const Text(
              'DELIVERY STATUS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            _buildPipeline(order.status),
            const Divider(height: 24),
          ],

          // Total Price & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Paid', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '₹${order.total.toInt()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (isCancellable)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    side: const BorderSide(color: Colors.red, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _confirmCancelOrder(order.id),
                  child: const Text('CANCEL ORDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading(width: 120, height: 16),
              ShimmerLoading(width: 80, height: 20, borderRadius: 4),
            ],
          ),
          SizedBox(height: 6),
          ShimmerLoading(width: 160, height: 12),
          SizedBox(height: 16),
          ShimmerLoading(height: 12),
          SizedBox(height: 6),
          ShimmerLoading(height: 12, width: 200),
          SizedBox(height: 6),
          ShimmerLoading(height: 12, width: 150),
          SizedBox(height: 16),
          ShimmerLoading(height: 40),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: 60, height: 12),
                  SizedBox(height: 4),
                  ShimmerLoading(width: 100, height: 20),
                ],
              ),
              ShimmerLoading(width: 100, height: 36, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipeline(String currentStatus) {
    final steps = ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered'];
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              // Circle node
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF10B981) : Colors.grey.shade300,
                ),
                child: isActive
                    ? const Center(child: Icon(Icons.check, size: 10, color: Colors.white))
                    : null,
              ),
              // Line connecter
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    color: index < currentIndex ? const Color(0xFF10B981) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
