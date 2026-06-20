import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchAndStartPolling();
  }

  void _fetchAndStartPolling() {
    ref.read(shopProvider.notifier).fetchTracking(widget.orderId);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(shopProvider.notifier).fetchTracking(widget.orderId);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(shopProvider.notifier).clearTracking();
    super.dispose();
  }

  OrderModel? _findOrder() {
    final orders = ref.read(shopProvider).orders;
    for (final o in orders) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final tracking = shopState.trackingData;
    final order = _findOrder();
    final isError = shopState.trackingError != null;

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
        title: Text(
          'ORDER #${widget.orderId.substring(widget.orderId.length - 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: shopState.trackingData == null && !isError
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isError
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: () => ref.read(shopProvider.notifier).fetchTracking(widget.orderId),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEtaBanner(tracking!),
                        const SizedBox(height: 20),
                        _buildTimeline(tracking),
                        const SizedBox(height: 20),
                        if (tracking.driverName != null) _buildDriverCard(tracking),
                        if (tracking.driverName != null) const SizedBox(height: 20),
                        _buildMapPlaceholder(tracking),
                        const SizedBox(height: 20),
                        if (order != null) _buildOrderSummary(order, tracking),
                        const SizedBox(height: 20),
                        _buildSupportButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsRegular.warning, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text(
            'Unable to load tracking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            ref.watch(shopProvider).trackingError ?? 'Something went wrong',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchAndStartPolling,
            icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
            label: const Text('RETRY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaBanner(TrackingData tracking) {
    final etaStr = tracking.estimatedDelivery != null
        ? DateFormat('MMM d, h:mm a').format(tracking.estimatedDelivery!)
        : 'Updates coming soon';

    final statusColor = _statusColor(tracking.currentStatus);
    final statusLabel = tracking.currentStatus.replaceAll('_', ' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.15), AppColors.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(tracking.currentStatus),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT STATUS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.clock, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Est. Delivery: $etaStr',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TrackingData tracking) {
    final steps = ['placed', 'confirmed', 'preparing', 'on_the_way', 'delivered'];
    final currentIndex = steps.indexOf(tracking.currentStatus);

    final timelineMap = <String, TrackingEvent>{};
    for (final event in tracking.timeline) {
      timelineMap[event.status] = event;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE TRACKING',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final status = steps[index];
            final event = timelineMap[status];
            final isActive = index <= currentIndex;
            final isCurrentStep = index == currentIndex;
            final isLast = index == steps.length - 1;

            final stepColor = isActive
                ? (isCurrentStep ? Colors.orange : const Color(0xFF10B981))
                : Colors.grey.shade300;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line + dot
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: isCurrentStep ? 18 : 14,
                          height: isCurrentStep ? 18 : 14,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? stepColor : Colors.grey.shade300,
                            border: isCurrentStep
                                ? Border.all(color: Colors.orange.shade400, width: 3)
                                : null,
                          ),
                          child: isActive
                              ? Icon(Icons.check, size: isCurrentStep ? 10 : 8, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: index < currentIndex
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Step label
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepLabel(status),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentStep ? FontWeight.w800 : FontWeight.w600,
                              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (event != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.clock, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('h:mm a').format(event.timestamp),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          if (event != null && event.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                event.description,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDriverCard(TrackingData tracking) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(PhosphorIconsRegular.motorcycle, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DELIVERY PARTNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                const SizedBox(height: 2),
                Text(
                  tracking.driverName ?? 'Driver',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (tracking.driverVehicle != null)
                  Text(
                    tracking.driverVehicle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (tracking.driverPhone != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(PhosphorIconsRegular.phoneCall, color: AppColors.primary, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${tracking.driverPhone}...'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(TrackingData tracking) {
    final hasCoords = tracking.driverLatitude != null && tracking.driverLongitude != null;

    return CustomCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasCoords ? PhosphorIconsRegular.mapPin : PhosphorIconsRegular.mapTrifold,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                hasCoords ? 'Driver is en route' : 'Live map view coming soon',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              if (hasCoords)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${tracking.driverLatitude!.toStringAsFixed(4)}, ${tracking.driverLongitude!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order, TrackingData tracking) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ORDER SUMMARY',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0),
              ),
              StatusBadge(
                text: order.status.replaceAll('_', ' ').toUpperCase(),
                dotColor: _statusColor(order.status),
                backgroundColor: _statusColor(order.status).withValues(alpha: 0.1),
                textColor: _statusColor(order.status),
              ),
            ],
          ),
          const Divider(height: 20),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toInt()}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          _summaryRow('Subtotal', '₹${order.subtotal.toInt()}'),
          _summaryRow('Delivery Fee', order.deliveryFee > 0 ? '₹${order.deliveryFee.toInt()}' : 'FREE'),
          _summaryRow('Tax (GST)', '₹${order.tax.toInt()}'),
          const Divider(height: 12),
          _summaryRow('Total Paid', '₹${order.total.toInt()}', isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacting support...'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        icon: const Icon(PhosphorIconsRegular.headset, size: 20),
        label: const Text('CONTACT SUPPORT'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _stepLabel(String status) {
    switch (status) {
      case 'placed': return 'Order Placed';
      case 'confirmed': return 'Order Confirmed';
      case 'preparing': return 'Preparing';
      case 'on_the_way': return 'On the Way';
      case 'delivered': return 'Delivered';
      default: return status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'placed': return Colors.blue;
      case 'confirmed': return Colors.indigo;
      case 'preparing': return Colors.orange;
      case 'on_the_way': return AppColors.primary;
      case 'delivered': return const Color(0xFF10B981);
      case 'cancelled': return AppColors.error;
      default: return AppColors.neutral;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'placed': return PhosphorIconsRegular.shoppingBag;
      case 'confirmed': return PhosphorIconsRegular.checkCircle;
      case 'preparing': return PhosphorIconsRegular.cookingPot;
      case 'on_the_way': return PhosphorIconsRegular.motorcycle;
      case 'delivered': return PhosphorIconsRegular.houseLine;
      default: return PhosphorIconsRegular.circle;
    }
  }
}
