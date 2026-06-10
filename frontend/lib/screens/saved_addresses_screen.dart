// lib/screens/saved_addresses_screen.dart
// ══════════════════════════════════════════════════════════════
//  SavedAddressesScreen
//  • Shows all locally-stored delivery addresses
//  • "+ Add New Address" → AddDeliveryAddressScreen
//  • Tap any address to select it for delivery
//  • Swipe-to-delete + set-default support
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/saved_address_model.dart';
import '../services/address_storage_service.dart';
import '../theme/theme.dart';
import 'add_delivery_address_screen.dart';

import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../models/models.dart';

class SavedAddressesScreen extends StatefulWidget {
  /// Passed from the map screen — pre-fills new address form
  final String? mapAddress;
  final String? mapShortName;

  const SavedAddressesScreen({
    super.key,
    this.mapAddress,
    this.mapShortName,
  });

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen>
    with SingleTickerProviderStateMixin {
  List<SavedAddress> _addresses = [];
  bool _loading = true;
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final addressProvider = context.read<AddressProvider>();
    await addressProvider.loadAddresses();
    if (!mounted) return;
    setState(() {
      _addresses = addressProvider.addresses.map((da) => _mapToSavedAddress(da)).toList();
      _loading   = false;
    });
    _listAnim.forward(from: 0);
  }

  // ── Navigate to Add Address ─────────────────────────────────
  Future<void> _goToAddAddress() async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AddDeliveryAddressScreen(
          mapAddress:   widget.mapAddress,
          mapShortName: widget.mapShortName,
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 360),
      ),
    );
    // Reload list in case a new address was added and user pressed back
    _load();
  }

  // ── Select address ──────────────────────────────────────────
  void _selectAddress(SavedAddress addr) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, addr); // return selected address to caller
  }

  // ── Set as default ──────────────────────────────────────────
  Future<void> _setDefault(SavedAddress addr) async {
    HapticFeedback.selectionClick();
    final success = await context.read<AddressProvider>().setDefault(addr.id);
    if (success) {
      _load();
      _snack('${addr.typeLabel} set as default address');
    } else {
      _snack('Failed to set default address', error: true);
    }
  }

  // ── Delete ──────────────────────────────────────────────────
  Future<void> _delete(SavedAddress addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Remove Address?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove this address?',
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Remove',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await context.read<AddressProvider>().deleteAddress(addr.id);
      if (success) {
        _load();
        _snack('Address removed');
      } else {
        _snack('Failed to remove address', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 13))),
        ]),
        backgroundColor: error ? const Color(0xFFEF4444) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────
            _buildHeader(topPad),

            // ── Body ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2.5,
                ),
              )
                  : _addresses.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
            ),
          ],
        ),

        // ── FAB: Add New Address ───────────────────────────────
        bottomNavigationBar: _buildAddButton(bottomPad),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.only(top: topPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 16, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textDark, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Saved Addresses',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (_addresses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_addresses.length} saved',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded,
                  size: 42, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'No Saved Addresses',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address\nand we\'ll save it for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _addresses.length,
      itemBuilder: (context, i) {
        final addr = _addresses[i];
        final delay = i * 60;
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _listAnim,
              curve: Interval(
                (delay / 600).clamp(0.0, 1.0),
                ((delay + 300) / 600).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _listAnim,
                curve: Interval(
                  (delay / 600).clamp(0.0, 1.0),
                  ((delay + 300) / 600).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _AddressTile(
              address:      addr,
              onTap:        () => _selectAddress(addr),
              onSetDefault: addr.isDefault ? null : () => _setDefault(addr),
              onDelete:     () => _delete(addr),
            ),
          ),
        );
      },
    );
  }

  // ── Add New Address button (bottom bar) ─────────────────────
  Widget _buildAddButton(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF34D399), AppTheme.primaryGreen, AppTheme.darkGreen],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _goToAddAddress,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_location_alt_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Address',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Address Tile
// ══════════════════════════════════════════════════════════════
class _AddressTile extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  const _AddressTile({
    required this.address,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDefault
                ? AppTheme.primaryGreen.withOpacity(0.35)
                : const Color(0xFFE8EDF4),
            width: isDefault ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDefault
                  ? AppTheme.primaryGreen.withOpacity(0.10)
                  : const Color(0x08000000),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: AppTheme.primaryGreen.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: type badge + default tag + actions ──
                  Row(
                    children: [
                      // Type icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: isDefault
                              ? const LinearGradient(
                            colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isDefault ? null : AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(address.addressType),
                          color: isDefault ? Colors.white : AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.typeLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              address.receiverName,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
                        onPressed: onDelete,
                        tooltip: 'Remove',
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Address text ─────────────────────────────
                  Text(
                    address.shortLine,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${address.city}${address.pincode.isNotEmpty ? " — ${address.pincode}" : ""}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  if (address.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          address.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Bottom: Set as default + Deliver here ────
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onSetDefault != null) ...[
                        GestureDetector(
                          onTap: onSetDefault,
                          child: Row(
                            children: [
                              const Icon(Icons.star_outline_rounded,
                                  size: 15, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Set as Default',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Deliver Here',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 11, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'home': return Icons.home_rounded;
      case 'work': return Icons.work_rounded;
      default:     return Icons.location_on_rounded;
    }
  }
}