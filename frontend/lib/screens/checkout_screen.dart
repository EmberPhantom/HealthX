import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../providers/address_provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import '../models/saved_address_model.dart';
import 'saved_addresses_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double _refW = 360;
  static const double _refH = 800;

  SavedAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  SavedAddress _mapToSavedAddress(DeliveryAddress da) {
    final parts = da.street.split('|');
    final flat = parts.isNotEmpty ? parts[0] : '';
    final society = parts.length > 1 ? parts[1] : '';
    final landmark = parts.length > 2 ? parts[2] : '';
    final receiverName = parts.length > 3 ? parts[3] : '';
    final phone = parts.length > 4 ? parts[4] : '';
    final state = parts.length > 5 ? parts[5] : '';

    return SavedAddress(
      id: da.id,
      addressType: da.label.toLowerCase() == 'home' || da.label.toLowerCase() == 'work' ? da.label.toLowerCase() : 'other',
      customLabel: da.label.toLowerCase() == 'home' || da.label.toLowerCase() == 'work' ? '' : da.label,
      flat: flat.isNotEmpty ? flat : da.street,
      society: society,
      landmark: landmark,
      area: da.area,
      city: da.city,
      state: state,
      pincode: da.pincode,
      receiverName: receiverName.isNotEmpty ? receiverName : 'Receiver',
      phone: phone,
      isDefault: da.isDefault,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final appProvider = context.watch<AppProvider>();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 16 : ws * 24;

    SavedAddress? activeAddress;
    if (_selectedAddress != null) {
      activeAddress = _selectedAddress;
    } else if (addressProvider.addresses.isNotEmpty) {
      final defaultDa = addressProvider.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressProvider.addresses.first,
      );
      activeAddress = _mapToSavedAddress(defaultDa);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  toolbarHeight: hs * 56,
                  leading: Padding(
                    padding: EdgeInsets.only(left: ws * 8),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: ws * 36,
                          height: ws * 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(ws * 10),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: ws * 16, color: const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    'Checkout',
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: ws * 18,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.2,
                    ),
                  ),
                  centerTitle: true,
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(hs * 1),
                    child: Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, hs * 16, hPad, hs * 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Delivery Address ───────────────────────────────────
                      _SectionLabel(label: 'Delivery Address', ws: ws, hs: hs),
                      SizedBox(height: hs * 8),
                      _AddressCard(
                        address: activeAddress,
                        ws: ws,
                        hs: hs,
                        onChange: () async {
                          final selected = await Navigator.push<SavedAddress>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedAddressesScreen(),
                            ),
                          );
                          if (selected != null) {
                            setState(() {
                              _selectedAddress = selected;
                            });
                          }
                        },
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.04, end: 0),
                      SizedBox(height: hs * 20),

                      // ── Delivery Time ──────────────────────────────────────
                      _SectionLabel(label: 'Delivery Time', ws: ws, hs: hs),
                      SizedBox(height: hs * 8),
                      _DeliveryTimeCard(provider: appProvider, ws: ws, hs: hs)
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 80.ms)
                          .slideY(begin: 0.04, end: 0),
                      SizedBox(height: hs * 20),

                      // ── Payment Method ─────────────────────────────────────
                      _SectionLabel(label: 'Payment Method', ws: ws, hs: hs),
                      SizedBox(height: hs * 8),
                      _PaymentCard(provider: appProvider, ws: ws, hs: hs)
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 160.ms)
                          .slideY(begin: 0.04, end: 0),
                      SizedBox(height: hs * 20),

                      // ── Order Summary ──────────────────────────────────────
                      _SectionLabel(label: 'Order Summary', ws: ws, hs: hs),
                      SizedBox(height: hs * 8),
                      _OrderSummaryCard(provider: appProvider, ws: ws, hs: hs)
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 240.ms)
                          .slideY(begin: 0.04, end: 0),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Place Order CTA ────────────────────────────────────────────────
          _PlaceOrderBar(
            appProvider: appProvider,
            address: activeAddress,
            hPad: hPad,
            ws: ws,
            hs: hs,
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final double ws, hs;

  const _SectionLabel({required this.label, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF0F172A),
        fontWeight: FontWeight.w700,
        fontSize: ws * 15,
        fontFamily: 'Poppins',
        letterSpacing: -0.1,
      ),
    );
  }
}

// ── Address Card ───────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final SavedAddress? address;
  final double ws, hs;
  final VoidCallback onChange;

  const _AddressCard(
      {required this.address, required this.ws, required this.hs, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: _cardDecoration(ws),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ws * 40,
            height: ws * 40,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(ws * 12),
            ),
            child: Icon(Icons.home_rounded,
                color: AppTheme.primaryGreen, size: ws * 20),
          ),
          SizedBox(width: ws * 12),
          Expanded(
            child: address == null
                ? Text(
                    'No delivery address saved.\nTap to add or select one.',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: ws * 13,
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: ws * 8, vertical: hs * 3),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(ws * 6),
                            ),
                            child: Text(
                              address!.typeLabel,
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: ws * 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: hs * 6),
                      Text(
                        address!.fullLine,
                        style: TextStyle(
                          color: const Color(0xFF475569),
                          fontSize: ws * 13,
                          fontFamily: 'Poppins',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChange();
            },
            child: Text(
              address == null ? 'Add' : 'Change',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: ws * 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery Time Card ─────────────────────────────────────────────────────────

class _DeliveryTimeCard extends StatelessWidget {
  final AppProvider provider;
  final double ws, hs;

  const _DeliveryTimeCard(
      {required this.provider, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: _cardDecoration(ws),
      child: Row(
        children: [
          _TimeChip(
            icon: Icons.bolt_rounded,
            label: 'ASAP',
            sublabel: '25–35 min',
            isSelected: provider.isAsapDelivery,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            ws: ws,
            hs: hs,
            onTap: () => provider.setDeliveryTime(true),
          ),
          SizedBox(width: ws * 10),
          _TimeChip(
            icon: Icons.schedule_rounded,
            label: 'Schedule',
            sublabel: 'Pick a time',
            isSelected: !provider.isAsapDelivery,
            color: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
            ws: ws,
            hs: hs,
            onTap: () => provider.setDeliveryTime(false),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool isSelected;
  final Color color, bgColor;
  final double ws, hs;
  final VoidCallback onTap;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.color,
    required this.bgColor,
    required this.ws,
    required this.hs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: ws * 12, vertical: hs * 12),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(ws * 12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ws * 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(ws * 8),
                ),
                child: Icon(icon,
                    size: ws * 16,
                    color: isSelected ? color : const Color(0xFF94A3B8)),
              ),
              SizedBox(width: ws * 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: isSelected ? color : const Color(0xFF94A3B8),
                      fontSize: ws * 10,
                      fontFamily: 'Poppins',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment Card ───────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final AppProvider provider;
  final double ws, hs;

  const _PaymentCard(
      {required this.provider, required this.ws, required this.hs});

  static const _methods = [
    _PayMethod(
      name: 'Credit Card',
      subtitle: 'Visa, Mastercard, Amex',
      icon: Icons.credit_card_rounded,
      gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
    ),
    _PayMethod(
      name: 'UPI',
      subtitle: 'PhonePe, GPay, Paytm',
      icon: Icons.account_balance_wallet_rounded,
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    _PayMethod(
      name: 'Net Banking',
      subtitle: 'All major banks',
      icon: Icons.account_balance_rounded,
      gradient: [Color(0xFFF093FB), Color(0xFFF5576C)],
    ),
    _PayMethod(
      name: 'Cash on Delivery',
      subtitle: 'Pay when delivered',
      icon: Icons.payments_rounded,
      gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(ws),
      child: Column(
        children: _methods.map((method) {
          final isSelected = provider.selectedPayment == method.name;
          final isLast = method == _methods.last;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setPaymentMethod(method.name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: isLast
                    ? BorderRadius.vertical(
                    bottom: Radius.circular(ws * 14))
                    : BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ws * 14, vertical: hs * 13),
                    child: Row(
                      children: [
                        // Gradient icon bg
                        Container(
                          width: ws * 38,
                          height: ws * 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: method.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(ws * 10),
                          ),
                          child: Icon(method.icon,
                              color: Colors.white, size: ws * 18),
                        ),
                        SizedBox(width: ws * 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.name,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: ws * 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                method.subtitle,
                                style: TextStyle(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: ws * 11,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: ws * 20,
                          height: ws * 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check_rounded,
                              color: Colors.white, size: ws * 12)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: ws * 64,
                      color: const Color(0xFFF1F5F9),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PayMethod {
  final String name, subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _PayMethod({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

// ── Order Summary Card ─────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final AppProvider provider;
  final double ws, hs;

  const _OrderSummaryCard(
      {required this.provider, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ws * 14),
      decoration: _cardDecoration(ws),
      child: Column(
        children: [
          ...provider.cartItems.map((ci) {
            return Padding(
              padding: EdgeInsets.only(bottom: hs * 10),
              child: Row(
                children: [
                  // Emoji badge
                  Container(
                    width: ws * 36,
                    height: ws * 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(ws * 9),
                    ),
                    child: Center(
                      child: Text(ci.menuItem.emoji,
                          style: TextStyle(fontSize: ws * 18)),
                    ),
                  ),
                  SizedBox(width: ws * 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ci.menuItem.name,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: ws * 13,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'x${ci.quantity}  ·  ₹${ci.menuItem.price.toStringAsFixed(0)} each',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: ws * 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${ci.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(height: hs * 16, color: const Color(0xFFF1F5F9)),
          _BillLine(
              label: 'Subtotal',
              value: '₹${provider.cartSubtotal.toStringAsFixed(0)}',
              ws: ws,
              hs: hs),
          _BillLine(
              label: 'Delivery',
              value: '₹${provider.deliveryFee.toStringAsFixed(0)}',
              ws: ws,
              hs: hs),
          _BillLine(
              label: 'Tax (5%)',
              value: '₹${provider.tax.toStringAsFixed(0)}',
              ws: ws,
              hs: hs),
          SizedBox(height: hs * 10),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: ws * 12, vertical: hs * 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(ws * 10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 15,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '₹${provider.cartTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 17,
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
}

class _BillLine extends StatelessWidget {
  final String label, value;
  final double ws, hs;

  const _BillLine(
      {required this.label,
        required this.value,
        required this.ws,
        required this.hs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: hs * 5),
      child: Row(
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
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: ws * 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Place Order Bar ────────────────────────────────────────────────────────────

class _PlaceOrderBar extends StatefulWidget {
  final AppProvider appProvider;
  final SavedAddress? address;
  final double hPad, ws, hs;

  const _PlaceOrderBar({
    required this.appProvider,
    required this.address,
    required this.hPad,
    required this.ws,
    required this.hs,
  });

  @override
  State<_PlaceOrderBar> createState() => _PlaceOrderBarState();
}

class _PlaceOrderBarState extends State<_PlaceOrderBar> {
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(widget.hPad, widget.hs * 12, widget.hPad, widget.hs * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, widget.hs * -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: widget.ws * 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '₹${widget.appProvider.cartTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: widget.ws * 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: widget.ws * 190,
                  height: widget.hs * 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(widget.ws * 14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(widget.ws * 14),
                      child: InkWell(
                        onTap: (widget.address == null || _isPlacing)
                            ? null
                            : () async {
                                HapticFeedback.heavyImpact();
                                setState(() => _isPlacing = true);
                                final success = await context.read<OrderProvider>().placeOrder(
                                      items: widget.appProvider.cartItems,
                                      addressId: widget.address!.id,
                                      paymentMethod: widget.appProvider.selectedPayment,
                                    );
                                if (!mounted) return;
                                setState(() => _isPlacing = false);
                                if (success) {
                                  widget.appProvider.clearCart();
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const OrderTrackingScreen()),
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to place order. Please try again.')),
                                  );
                                }
                              },
                        borderRadius: BorderRadius.circular(widget.ws * 14),
                        splashColor: Colors.white.withOpacity(0.15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isPlacing)
                              SizedBox(
                                width: widget.ws * 18,
                                height: widget.ws * 18,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            else ...[
                              Icon(Icons.shopping_bag_rounded,
                                  color: Colors.white, size: widget.ws * 18),
                              SizedBox(width: widget.ws * 7),
                              Text(
                                'Place Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: widget.ws * 15,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ]
                          ],
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

// ── Shared helper ──────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration(double ws) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(ws * 14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}