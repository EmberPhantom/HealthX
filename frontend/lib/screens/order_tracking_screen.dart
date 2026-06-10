import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 16 : ws * 24;

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📦', style: TextStyle(fontSize: ws * 52)),
              SizedBox(height: hs * 16),
              Text(
                'No active order',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: ws * 20,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: hs * 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: ws * 24, vertical: hs * 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(ws * 14),
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final eta = order.estimatedDelivery;
    final minsLeft = eta.difference(now).inMinutes.clamp(0, 60);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Success Header ─────────────────────────────────────────────
              _SuccessHeader(
                orderId: order.id,
                minsLeft: minsLeft,
                ws: ws,
                hs: hs,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),

              Padding(
                padding: EdgeInsets.fromLTRB(hPad, hs * 20, hPad, hs * 32),
                child: Column(
                  children: [
                    // ── Live Status Bar ──────────────────────────────────────
                    _LiveStatusBar(order: order, ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms),

                    SizedBox(height: hs * 20),

                    // ── Progress Timeline ────────────────────────────────────
                    _ProgressTimeline(order: order, ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms),

                    SizedBox(height: hs * 20),

                    // ── Delivery Partner ─────────────────────────────────────
                    if (order.deliveryPartner != null)
                      _DeliveryPartnerCard(
                        partner: order.deliveryPartner!,
                        ws: ws,
                        hs: hs,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.04, end: 0),

                    SizedBox(height: hs * 16),

                    // ── Order Details ────────────────────────────────────────
                    _OrderDetailsCard(order: order, ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.04, end: 0),

                    SizedBox(height: hs * 20),

                    // ── Delivery Address ─────────────────────────────────────
                    _DeliveryAddressCard(order: order, ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 460.ms)
                        .slideY(begin: 0.04, end: 0),

                    SizedBox(height: hs * 24),

                    // ── Actions ──────────────────────────────────────────────
                    _ActionButtons(ws: ws, hs: hs),
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

// ── Success Header ─────────────────────────────────────────────────────────────

class _SuccessHeader extends StatelessWidget {
  final String orderId;
  final int minsLeft;
  final double ws, hs;

  const _SuccessHeader({
    required this.orderId,
    required this.minsLeft,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + hs * 20,
            bottom: hs * 32,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Animated check
              Container(
                width: ws * 70,
                height: ws * 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.white, size: ws * 36),
              )
                  .animate()
                  .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
                delay: 100.ms,
              ),
              SizedBox(height: hs * 14),
              Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: ws * 22,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: hs * 4),
              Text(
                'Order #$orderId',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: ws * 13,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: hs * 18),
              // ETA pill
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ws * 20, vertical: hs * 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(ws * 30),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_filled_rounded,
                        color: Colors.white, size: ws * 16),
                    SizedBox(width: ws * 6),
                    Text(
                      'Arriving in $minsLeft–${minsLeft + 5} mins',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: ws * 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Live Status Bar ────────────────────────────────────────────────────────────

class _LiveStatusBar extends StatelessWidget {
  final Order order;
  final double ws, hs;
  const _LiveStatusBar({required this.order, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    String statusTitle = 'Your order is being prepared';
    String statusDesc = 'Restaurant has confirmed your order';

    switch (order.status) {
      case OrderStatus.placed:
        statusTitle = 'Order placed';
        statusDesc = 'Waiting for kitchen confirmation';
        break;
      case OrderStatus.preparing:
        statusTitle = 'Preparing your meal';
        statusDesc = 'Kitchen is carefully crafting your food';
        break;
      case OrderStatus.outForDelivery:
        statusTitle = 'Out for delivery';
        statusDesc = 'Our partner is en route to you';
        break;
      case OrderStatus.delivered:
        statusTitle = 'Delivered';
        statusDesc = 'Hope you enjoy your healthy meal!';
        break;
      case OrderStatus.cancelled:
        statusTitle = 'Order Cancelled';
        statusDesc = 'This order has been cancelled';
        break;
    }

    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ws * 14, vertical: hs * 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ws * 10,
            height: ws * 10,
            decoration: BoxDecoration(
              color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.5, duration: 800.ms, curve: Curves.easeOut)
              .then()
              .scaleXY(end: 1.0, duration: 800.ms),
          SizedBox(width: ws * 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: ws * 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  statusDesc,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            EdgeInsets.symmetric(horizontal: ws * 8, vertical: hs * 4),
            decoration: BoxDecoration(
              color: isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(ws * 8),
            ),
            child: Text(
              isCancelled ? 'CANCELLED' : 'LIVE',
              style: TextStyle(
                color: isCancelled ? const Color(0xFFEF4444) : AppTheme.primaryGreen,
                fontWeight: FontWeight.w800,
                fontSize: ws * 10,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Timeline ──────────────────────────────────────────────────────────

class _ProgressTimeline extends StatelessWidget {
  final Order order;
  final double ws, hs;
  const _ProgressTimeline({required this.order, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final isPlacedDone = status == OrderStatus.placed || status == OrderStatus.preparing || status == OrderStatus.outForDelivery || status == OrderStatus.delivered;
    final isPreparingDone = status == OrderStatus.preparing || status == OrderStatus.outForDelivery || status == OrderStatus.delivered;
    final isOnTheWayDone = status == OrderStatus.outForDelivery || status == OrderStatus.delivered;
    final isDeliveredDone = status == OrderStatus.delivered;

    final steps = [
      _Step(
        title: 'Order Placed',
        desc: 'We have received your order',
        icon: Icons.receipt_long_rounded,
        isDone: isPlacedDone && status != OrderStatus.placed,
        isActive: status == OrderStatus.placed,
      ),
      _Step(
        title: 'Preparing',
        desc: 'Kitchen is making your meal',
        icon: Icons.restaurant_rounded,
        isDone: isPreparingDone && status != OrderStatus.preparing,
        isActive: status == OrderStatus.preparing,
      ),
      _Step(
        title: 'On the way',
        desc: 'Delivery partner en route',
        icon: Icons.delivery_dining_rounded,
        isDone: isOnTheWayDone && status != OrderStatus.outForDelivery,
        isActive: status == OrderStatus.outForDelivery,
      ),
      _Step(
        title: status == OrderStatus.cancelled ? 'Cancelled' : 'Delivered',
        desc: status == OrderStatus.cancelled ? 'Order was cancelled' : 'Enjoy your meal!',
        icon: status == OrderStatus.cancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
        isDone: isDeliveredDone || status == OrderStatus.cancelled,
        isActive: false,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              Column(
                children: [
                  // Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: ws * 34,
                    height: ws * 34,
                    decoration: BoxDecoration(
                      color: step.isDone
                          ? (status == OrderStatus.cancelled && i == steps.length - 1 ? const Color(0xFFEF4444) : AppTheme.primaryGreen)
                          : step.isActive
                          ? AppTheme.lightGreen
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: step.isActive
                          ? Border.all(
                          color: AppTheme.primaryGreen, width: 2)
                          : null,
                    ),
                    child: Icon(
                      step.icon,
                      size: ws * 16,
                      color: step.isDone
                          ? Colors.white
                          : step.isActive
                          ? AppTheme.primaryGreen
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  // Line
                  if (!isLast)
                    Container(
                      width: ws * 2,
                      height: hs * 34,
                      decoration: BoxDecoration(
                        gradient: step.isDone
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFFD1FAE5)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                            : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
                        ),
                        borderRadius: BorderRadius.circular(ws * 2),
                      ),
                    ),
                ],
              ),
              SizedBox(width: ws * 12),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: ws * 6, bottom: isLast ? 0 : hs * 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: step.isDone || step.isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                          fontWeight: step.isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: ws * 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: hs * 2),
                      Text(
                        step.desc,
                        style: TextStyle(
                          color: step.isActive
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          fontSize: ws * 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (step.isActive) ...[
                        SizedBox(height: hs * 5),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: ws * 8, vertical: hs * 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(ws * 6),
                          ),
                          child: Text(
                            '⏱ In progress...',
                            style: TextStyle(
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                              fontSize: ws * 10,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Step {
  final String title, desc;
  final IconData icon;
  final bool isDone, isActive;

  const _Step({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isDone,
    required this.isActive,
  });
}

// ── Delivery Partner Card ──────────────────────────────────────────────────────

class _DeliveryPartnerCard extends StatelessWidget {
  final DeliveryPartner partner;
  final double ws, hs;

  const _DeliveryPartnerCard(
      {required this.partner, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Partner',
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: ws * 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: hs * 10),
          Row(
            children: [
              // Avatar
              Container(
                width: ws * 50,
                height: ws * 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    partner.name.substring(0, 1),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: ws * 20,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              SizedBox(width: ws * 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: TextStyle(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        fontSize: ws * 15,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: hs * 3),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: const Color(0xFFF59E0B), size: ws * 13),
                        SizedBox(width: ws * 3),
                        Text(
                          '${partner.rating}',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: ws * 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: ws * 4),
                        Text(
                          '·  ${partner.deliveries} deliveries',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: ws * 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call & Chat
              Row(
                children: [
                  _PartnerActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF6366F1),
                    ws: ws,
                    hs: hs,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  SizedBox(width: ws * 8),
                  _PartnerActionBtn(
                    icon: Icons.phone_rounded,
                    color: AppTheme.primaryGreen,
                    ws: ws,
                    hs: hs,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double ws, hs;
  final VoidCallback onTap;

  const _PartnerActionBtn({
    required this.icon,
    required this.color,
    required this.ws,
    required this.hs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ws * 40,
        height: ws * 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ws * 12),
        ),
        child: Icon(icon, color: color, size: ws * 18),
      ),
    );
  }
}

// ── Order Details Card ─────────────────────────────────────────────────────────

class _OrderDetailsCard extends StatelessWidget {
  final Order order;
  final double ws, hs;

  const _OrderDetailsCard(
      {required this.order, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Details',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: ws * 15,
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ws * 8, vertical: hs * 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(ws * 7),
                ),
                child: Text(
                  '#${order.id}',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 10,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: hs * 12),
          ...order.items.map<Widget>((ci) {
            return Padding(
              padding: EdgeInsets.only(bottom: hs * 8),
              child: Row(
                children: [
                  Container(
                    width: ws * 34,
                    height: ws * 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(ws * 9),
                    ),
                    child: Center(
                      child: Text(ci.menuItem.emoji,
                          style: TextStyle(fontSize: ws * 17)),
                    ),
                  ),
                  SizedBox(width: ws * 10),
                  Expanded(
                    child: Text(
                      '${ci.menuItem.name}',
                      style: TextStyle(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: ws * 13,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'x${ci.quantity}',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: ws * 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: ws * 12),
                  Text(
                    '₹${ci.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(height: hs * 16, color: const Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: ws * 14,
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ws * 12, vertical: hs * 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(ws * 8),
                ),
                child: Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: hs * 10),
          Row(
            children: [
              Icon(Icons.payment_rounded,
                  size: ws * 14, color: const Color(0xFF94A3B8)),
              SizedBox(width: ws * 6),
              Text(
                'Paid via ${order.paymentMethod}',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: ws * 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Delivery Address Card ──────────────────────────────────────────────────────

class _DeliveryAddressCard extends StatelessWidget {
  final Order order;
  final double ws, hs;

  const _DeliveryAddressCard(
      {required this.order, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final addr = order.address;
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ws * 40,
            height: ws * 40,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(ws * 12),
            ),
            child: Icon(Icons.location_on_rounded,
                color: AppTheme.primaryGreen, size: ws * 20),
          ),
          SizedBox(width: ws * 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to ${addr.label}',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: ws * 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: hs * 3),
                Text(
                  addr.fullAddress,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 12,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final double ws, hs;
  const _ActionButtons({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cancel
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showDialog(
              context: context,
              builder: (ctx) => _CancelDialog(ws: ws, hs: hs),
            );
          },
          child: Container(
            width: double.infinity,
            height: hs * 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ws * 14),
              border: Border.all(
                  color: const Color(0xFFEF4444), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Cancel Order',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                  fontSize: ws * 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: hs * 12),

        // Back to Home
        GestureDetector(
          onTap: () {
            context.read<AppProvider>().setTabIndex(0);
            Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: Container(
            width: double.infinity,
            height: hs * 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(ws * 14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white, size: ws * 18),
                  SizedBox(width: ws * 8),
                  Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cancel Dialog ──────────────────────────────────────────────────────────────

class _CancelDialog extends StatelessWidget {
  final double ws, hs;

  const _CancelDialog({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ws * 18),
      ),
      child: Padding(
        padding: EdgeInsets.all(ws * 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😔', style: TextStyle(fontSize: ws * 40)),
            SizedBox(height: hs * 10),
            Text(
              'Cancel Order?',
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: ws * 18,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: hs * 6),
            Text(
              'Are you sure you want to cancel this order? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: ws * 13,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            SizedBox(height: hs * 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: ws * 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(ws * 12),
                      ),
                      child: Center(
                        child: Text(
                          'Keep Order',
                          style: TextStyle(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: ws * 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ws * 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final orderId = context.read<OrderProvider>().currentOrder?.id;
                      if (orderId != null) {
                        await context.read<OrderProvider>().cancelOrder(orderId, cancelReason: 'User cancelled');
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      height: ws * 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(ws * 12),
                      ),
                      child: Center(
                        child: Text(
                          'Yes, Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: ws * 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}