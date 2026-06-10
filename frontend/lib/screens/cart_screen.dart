import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'checkout_screen.dart';
import 'image_zoom_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cartItems = provider.cartItems;
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 16 : ws * 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _CartHeader(
              ws: ws,
              hs: hs,
              hPad: hPad,
              itemCount: provider.cartItemCount,
              hasItems: cartItems.isNotEmpty,
              onClear: provider.clearCart,
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: cartItems.isEmpty
                  ? _EmptyCart(ws: ws, hs: hs)
                  : ListView.builder(
                padding: EdgeInsets.fromLTRB(hPad, hs * 4, hPad, hs * 12),
                physics: const BouncingScrollPhysics(),
                itemCount: cartItems.length + 1, // +1 for promo
                itemBuilder: (context, index) {
                  if (index == cartItems.length) {
                    return _PromoCodeWidget(ws: ws, hs: hs)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 200.ms);
                  }
                  return _CartItemCard(
                    cartItem: cartItems[index],
                    ws: ws,
                    hs: hs,
                  )
                      .animate()
                      .fadeIn(
                    duration: 280.ms,
                    delay: Duration(milliseconds: 60 * index),
                  )
                      .slideX(begin: 0.03, end: 0);
                },
              ),
            ),

            // ── Bottom Summary ───────────────────────────────────────────────
            if (cartItems.isNotEmpty)
              _BottomSummary(
                provider: provider,
                hPad: hPad,
                ws: ws,
                hs: hs,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Cart Header ────────────────────────────────────────────────────────────────

class _CartHeader extends StatelessWidget {
  final double ws, hs, hPad;
  final int itemCount;
  final bool hasItems;
  final VoidCallback onClear;

  const _CartHeader({
    required this.ws,
    required this.hs,
    required this.hPad,
    required this.itemCount,
    required this.hasItems,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, hs * 16, hPad, hs * 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Cart',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 22,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: hs * 2),
                Text(
                  hasItems ? '$itemCount item${itemCount > 1 ? 's' : ''} added' : 'Nothing here yet',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (hasItems)
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                showDialog(
                  context: context,
                  builder: (_) => _ClearCartDialog(ws: ws, onConfirm: onClear),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: ws * 12, vertical: hs * 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(ws * 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: ws * 15, color: const Color(0xFFEF4444)),
                    SizedBox(width: ws * 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: ws * 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cart Item Card ──────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final double ws, hs;

  const _CartItemCard({required this.cartItem, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final item = cartItem.menuItem;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.removeFromCart(item.id);
      },
      background: Container(
        margin: EdgeInsets.only(bottom: hs * 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(ws * 14),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: ws * 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: ws * 22),
            SizedBox(height: hs * 3),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: ws * 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: hs * 10),
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
        child: Padding(
          padding: EdgeInsets.all(ws * 12),
          child: Row(
            children: [
              // Image — tap to open full zoom viewer
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black,
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, __, ___) => ImageZoomScreen(
                        args: ImageZoomArgs(
                          imageUrls: [
                            item.imageUrl,
                            item.imageUrl, // fallback — detail screen passes real 3 images
                          ],
                          initialIndex: 0,
                          productName: item.name,
                        ),
                      ),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ws * 10),
                  child: _ProductImage(
                    imageUrl: item.imageUrl,
                    size: ws * 72,
                    ws: ws,
                  ),
                ),
              ),
              SizedBox(width: ws * 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Veg indicator
                        Container(
                          width: ws * 13,
                          height: ws * 13,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isVeg
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(ws * 2),
                          ),
                          child: Center(
                            child: Container(
                              width: ws * 6,
                              height: ws * 6,
                              decoration: BoxDecoration(
                                color: item.isVeg
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ws * 6),
                        Expanded(
                          child: Text(
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
                        ),
                      ],
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
                    SizedBox(height: hs * 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${cartItem.subtotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: ws * 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        // Qty stepper
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(ws * 9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.updateQuantity(
                                      item.id, cartItem.quantity - 1);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ws * 9,
                                    vertical: hs * 6,
                                  ),
                                  child: Icon(
                                    cartItem.quantity == 1
                                        ? Icons.delete_outline_rounded
                                        : Icons.remove,
                                    size: ws * 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: ws * 22,
                                child: Text(
                                  '${cartItem.quantity}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: ws * 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.updateQuantity(
                                      item.id, cartItem.quantity + 1);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ws * 9,
                                    vertical: hs * 6,
                                  ),
                                  child: Icon(Icons.add,
                                      size: ws * 15, color: Colors.white),
                                ),
                              ),
                            ],
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
    );
  }
}

// ── Promo Code Widget ──────────────────────────────────────────────────────────

class _PromoCodeWidget extends StatefulWidget {
  final double ws, hs;
  const _PromoCodeWidget({required this.ws, required this.hs});

  @override
  State<_PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<_PromoCodeWidget>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _applied = false;
  bool _isFocused = false;
  late AnimationController _successAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut),
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  void _applyPromo() {
    if (_ctrl.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      _focusNode.unfocus();
      setState(() => _applied = true);
      _successAnim.forward(from: 0);
    }
  }

  void _removePromo() {
    HapticFeedback.lightImpact();
    _ctrl.clear();
    setState(() => _applied = false);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;

    return Container(
      margin: EdgeInsets.only(top: hs * 6, bottom: hs * 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: ws * 2, bottom: hs * 8),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  size: ws * 13,
                  color: const Color(0xFF64748B),
                ),
                SizedBox(width: ws * 5),
                Text(
                  'PROMO CODE',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: ws * 10.5,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // ── Main card ─────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ws * 14),
              border: Border.all(
                color: _applied
                    ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                    : _isFocused
                    ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: _applied || _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _applied
                      ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                      : _isFocused
                      ? AppTheme.primaryGreen.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _isFocused || _applied ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _applied
                ? _AppliedState(
              ws: ws,
              hs: hs,
              scaleAnim: _scaleAnim,
              onRemove: _removePromo,
              code: _ctrl.text.trim().toUpperCase(),
            )
                : _InputState(
              ws: ws,
              hs: hs,
              ctrl: _ctrl,
              focusNode: _focusNode,
              onApply: _applyPromo,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Applied State ──────────────────────────────────────────────────────────────

class _AppliedState extends StatelessWidget {
  final double ws, hs;
  final Animation<double> scaleAnim;
  final VoidCallback onRemove;
  final String code;

  const _AppliedState({
    required this.ws,
    required this.hs,
    required this.scaleAnim,
    required this.onRemove,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ws * 14, vertical: hs * 13),
      child: ScaleTransition(
        scale: scaleAnim,
        child: Row(
          children: [
            // Success icon
            Container(
              width: ws * 36,
              height: ws * 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreen.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: ws * 18,
              ),
            ),
            SizedBox(width: ws * 12),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: ws * 7, vertical: hs * 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ws * 4),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: ws * 11,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: ws * 6),
                      Text(
                        'applied!',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: ws * 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: hs * 3),
                  Text(
                    'You saved ₹20 on this order 🎉',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: ws * 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: ws * 28,
                height: ws * 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: ws * 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input State ────────────────────────────────────────────────────────────────

class _InputState extends StatelessWidget {
  final double ws, hs;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final VoidCallback onApply;

  const _InputState({
    required this.ws,
    required this.hs,
    required this.ctrl,
    required this.focusNode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(ws * 14, hs * 10, ws * 8, hs * 10),
      child: Row(
        children: [
          // Tag icon box
          Container(
            width: ws * 32,
            height: ws * 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(ws * 8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              Icons.discount_outlined,
              size: ws * 16,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(width: ws * 10),

          // Text field
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => onApply(),
              style: TextStyle(
                fontSize: ws * 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: 0.8,
              ),
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: TextStyle(
                  color: const Color(0xFFCBD5E1),
                  fontSize: ws * 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: hs * 2),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(width: ws * 8),

          // Apply button — reactive via AnimatedBuilder
          AnimatedBuilder(
            animation: ctrl,
            builder: (context, _) {
              final hasText = ctrl.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: onApply,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: ws * 16, vertical: hs * 10),
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: hasText ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(ws * 10),
                    boxShadow: hasText
                        ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen
                            .withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: hasText ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 12.5,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Bottom Summary ─────────────────────────────────────────────────────────────

class _BottomSummary extends StatelessWidget {
  final AppProvider provider;
  final double hPad, ws, hs;

  const _BottomSummary({
    required this.provider,
    required this.hPad,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, hs * 14, hPad, hs * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ws * 22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: Offset(0, hs * -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bill breakdown
            _BillRow(
              label: 'Item Total',
              value: '₹${provider.cartSubtotal.toStringAsFixed(0)}',
              ws: ws,
            ),
            SizedBox(height: hs * 6),
            _BillRow(
              label: 'Delivery Fee',
              value: '₹${provider.deliveryFee.toStringAsFixed(0)}',
              ws: ws,
              valueColor: provider.deliveryFee == 0
                  ? AppTheme.primaryGreen
                  : null,
            ),
            SizedBox(height: hs * 6),
            _BillRow(
              label: 'Taxes & Charges',
              value: '₹${provider.tax.toStringAsFixed(0)}',
              ws: ws,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: hs * 10),
              child: Row(
                children: List.generate(
                  30,
                      (i) => Expanded(
                    child: Container(
                      height: 1,
                      color: i.isEven
                          ? const Color(0xFFE2E8F0)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To Pay',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '₹${provider.cartTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: hs * 14),
            SizedBox(
              width: double.infinity,
              height: hs * 52,
              child: DecoratedBox(
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(ws * 14),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(ws * 14),
                    splashColor: Colors.white.withValues(alpha: 0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: ws * 15,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: ws * 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: ws * 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label, value;
  final double ws;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    required this.ws,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: ws * 13,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: ws * 13,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

// ── Empty Cart ─────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final double ws, hs;
  const _EmptyCart({required this.ws, required this.hs});

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
              child: Text('🛒', style: TextStyle(fontSize: ws * 44)),
            ),
          ),
          SizedBox(height: hs * 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: ws * 20,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: hs * 8),
          Text(
            'Add items from the menu\nto get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: ws * 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          SizedBox(height: hs * 28),
          GestureDetector(
            onTap: () => context.read<AppProvider>().setTabIndex(1),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: ws * 24, vertical: hs * 14),
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
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// ── Clear Cart Dialog ──────────────────────────────────────────────────────────

class _ClearCartDialog extends StatelessWidget {
  final double ws;
  final VoidCallback onConfirm;

  const _ClearCartDialog({required this.ws, required this.onConfirm});

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
            Container(
              width: ws * 56,
              height: ws * 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444), size: ws * 28),
            ),
            SizedBox(height: ws * 14),
            Text(
              'Clear Cart?',
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: ws * 18,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: ws * 8),
            Text(
              'All items will be removed from your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: ws * 13,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            SizedBox(height: ws * 20),
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
                          'Cancel',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: ws * 14,
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
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      height: ws * 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(ws * 12),
                      ),
                      child: Center(
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: ws * 14,
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

// ── Smart Product Image — handles local assets & network URLs ─────────────────

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double ws;
  const _ProductImage(
      {required this.imageUrl, required this.size, required this.ws});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(ws * 10),
    ),
    child: Center(
      child: Text('🛒', style: TextStyle(fontSize: size * 0.38)),
    ),
  );
}