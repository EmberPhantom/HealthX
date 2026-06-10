import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const double _refW = 360;
  static const double _refH = 800;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 18 : ws * 24;

    final allOrders = orderProvider.orders;

    final activeOrders = allOrders
        .where((o) =>
    o.status != OrderStatus.delivered &&
        o.status != OrderStatus.cancelled)
        .toList();
    final pastOrders = allOrders
        .where((o) =>
    o.status == OrderStatus.delivered ||
        o.status == OrderStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            _buildHeader(context, ws, hs, hPad),

            // ── Tabs ──────────────────────────────────────────────────────
            _buildTabs(ws, hs, hPad),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(
                    orders: activeOrders,
                    ws: ws,
                    hs: hs,
                    hPad: hPad,
                    isActive: true,
                  ),
                  _OrdersList(
                    orders: pastOrders,
                    ws: ws,
                    hs: hs,
                    hPad: hPad,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, double ws, double hs, double hPad) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, hs * 16, hPad, hs * 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: ws * 38,
              height: ws * 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(ws * 10),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: ws * 19, color: const Color(0xFF0F172A)),
            ),
          ),
          SizedBox(width: ws * 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Orders',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 21,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Track & view your order history',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(double ws, double hs, double hPad) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, hs * 4),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 2.5,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: ws * 13,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: ws * 13,
          fontFamily: 'Poppins',
        ),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Past Orders'),
        ],
      ),
    );
  }
}

// ── Orders List ────────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final double ws, hs, hPad;
  final bool isActive;

  const _OrdersList({
    required this.orders,
    required this.ws,
    required this.hs,
    required this.hPad,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyOrders(ws: ws, hs: hs, isActive: isActive);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hPad, hs * 14, hPad, hs * 24),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(
          order: orders[index],
          ws: ws,
          hs: hs,
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: Duration(milliseconds: 60 * index))
            .slideY(begin: 0.04, end: 0);
      },
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  final double ws, hs;

  const _OrderCard({required this.order, required this.ws, required this.hs});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const Color(0xFF3B82F6);
      case OrderStatus.preparing:
        return const Color(0xFFF59E0B);
      case OrderStatus.outForDelivery:
        return AppTheme.primaryGreen;
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingleProduct = order.items.length == 1;
    final statusColor = _statusColor(order.status);
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isCompleted = isDelivered || isCancelled;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Navigate to order tracking
        // Set current order to this one so tracking screen can show it
        final prov = context.read<OrderProvider>();
        if (prov.currentOrder?.id != order.id) {
          // Re-surface this order as current for tracking view
          prov.setViewingOrder(order);
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: hs * 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ws * 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: Order ID + Status ─────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                  ws * 16, hs * 14, ws * 14, hs * 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ws * 16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ws * 7),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(order.status),
                      size: ws * 16,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: ws * 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: ws * 13.5,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: hs * 1),
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: ws * 11.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ws * 10, vertical: hs * 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ws * 20),
                    ),
                    child: Text(
                      _statusLabel(order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: ws * 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Product Preview ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(ws * 14),
              child: isSingleProduct
                  ? _SingleProductView(
                  cartItem: order.items.first, ws: ws, hs: hs)
                  : _MultiProductView(items: order.items, ws: ws, hs: hs),
            ),

            // ── Divider ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ws * 14),
              child: Divider(
                  height: 1, thickness: 1, color: const Color(0xFFF1F5F9)),
            ),

            // ── Bottom: Date + CTA ────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(ws * 14, hs * 10, ws * 14, hs * 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: ws * 13,
                          color: const Color(0xFF94A3B8)),
                      SizedBox(width: ws * 4),
                      Text(
                        isCompleted ? 'Completed' : 'In progress...',
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontSize: ws * 11.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCompleted ? 'View Details' : 'Track Order',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: ws * 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: ws * 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: ws * 10, color: AppTheme.primaryGreen),
                    ],
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

// ── Single Product View ────────────────────────────────────────────────────────

class _SingleProductView extends StatelessWidget {
  final CartItem cartItem;
  final double ws, hs;

  const _SingleProductView(
      {required this.cartItem, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final item = cartItem.menuItem;
    return Row(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(ws * 10),
          child: _ProductImage(
            imageUrl: item.imageUrl,
            size: ws * 70,
            ws: ws,
          ),
        ),
        SizedBox(width: ws * 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: ws * 14,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: hs * 3),
              Text(
                item.description,
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: ws * 11,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: hs * 6),
              Row(
                children: [
                  _QtyBadge(qty: cartItem.quantity, ws: ws),
                  SizedBox(width: ws * 8),
                  Text(
                    '₹${cartItem.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: ws * 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Multi Product View ─────────────────────────────────────────────────────────

class _MultiProductView extends StatelessWidget {
  final List<CartItem> items;
  final double ws, hs;

  const _MultiProductView(
      {required this.items, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    // Show up to 3 images stacked, then list items
    final previewItems = items.take(4).toList();
    final extra = items.length > 4 ? items.length - 4 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image strip
        Row(
          children: [
            ...previewItems.map((ci) => Padding(
              padding: EdgeInsets.only(right: ws * 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ws * 8),
                child: ci.menuItem.imageUrl.isNotEmpty
                    ? _ProductImage(
                  imageUrl: ci.menuItem.imageUrl,
                  size: ws * 54,
                  ws: ws,
                )
                    : _PlaceholderImage(ws: ws, size: ws * 54),
              ),
            )),
            if (extra > 0)
              Container(
                width: ws * 54,
                height: ws * 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(ws * 8),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: hs * 10),
        // Item list (show max 3)
        ...items.take(3).map((ci) => Padding(
          padding: EdgeInsets.only(bottom: hs * 5),
          child: Row(
            children: [
              _QtyBadge(qty: ci.quantity, ws: ws),
              SizedBox(width: ws * 8),
              Expanded(
                child: Text(
                  ci.menuItem.name,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: ws * 12.5,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${ci.subtotal.toStringAsFixed(0)}',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: ws * 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        )),
        if (items.length > 3)
          Text(
            '+ ${items.length - 3} more item${items.length - 3 > 1 ? 's' : ''}',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: ws * 11.5,
              fontFamily: 'Poppins',
            ),
          ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _QtyBadge extends StatelessWidget {
  final int qty;
  final double ws;
  const _QtyBadge({required this.qty, required this.ws});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ws * 7, vertical: ws * 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ws * 5),
      ),
      child: Text(
        '×$qty',
        style: TextStyle(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w700,
          fontSize: ws * 11,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ── Smart Product Image — handles both local assets and network URLs ───────────

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double ws;
  const _ProductImage({required this.imageUrl, required this.size, required this.ws});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PlaceholderImage(ws: ws, size: size),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PlaceholderImage(ws: ws, size: size),
      );
    }
    return _PlaceholderImage(ws: ws, size: size);
  }
}

// ── Placeholder Image ─────────────────────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  final double ws;
  final double? size;
  const _PlaceholderImage({required this.ws, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? ws * 70;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(ws * 10),
      ),
      child: Center(
        child: Text('🥗', style: TextStyle(fontSize: s * 0.4)),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  final double ws, hs;
  final bool isActive;
  const _EmptyOrders(
      {required this.ws, required this.hs, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ws * 100,
            height: ws * 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isActive ? '📦' : '🧾',
                style: TextStyle(fontSize: ws * 44),
              ),
            ),
          ),
          SizedBox(height: hs * 20),
          Text(
            isActive ? 'No active orders' : 'No past orders',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: ws * 19,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: hs * 8),
          Text(
            isActive
                ? 'Place an order to see it here'
                : 'Your completed orders will\nappear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: ws * 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          if (isActive) ...[
            SizedBox(height: hs * 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.read<AppProvider>().setTabIndex(1);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ws * 24, vertical: hs * 13),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(ws * 14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu_rounded,
                        color: Colors.white, size: ws * 17),
                    SizedBox(width: ws * 8),
                    Text(
                      'Browse Menu',
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
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}