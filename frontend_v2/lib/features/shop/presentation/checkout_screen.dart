import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/shop_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  String _paymentMethod = 'cod';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _selectDefaultAddress());
  }

  void _selectDefaultAddress() {
    final addresses = ref.read(shopProvider).addresses;
    if (addresses.isNotEmpty) {
      final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      setState(() => _selectedAddressId = def.id);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address'), backgroundColor: AppColors.error),
      );
      return;
    }

    HapticFeedback.vibrate();
    final success = await ref.read(shopProvider.notifier).checkout(
          addressId: _selectedAddressId!,
          paymentMethod: _paymentMethod,
        );

    if (mounted) {
      if (success) {
        // Clear routes and push to Orders screen
        context.go('/shop');
        context.push('/shop/orders');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! Track your delivery status.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(shopProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to place order. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final addresses = shopState.addresses;

    // Check if the selected address ID is still valid
    if (_selectedAddressId == null && addresses.isNotEmpty) {
      _selectedAddressId = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first).id;
    }

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
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: shopState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shipping Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SHIPPING ADDRESS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          context.push('/shop/addresses');
                        },
                        icon: const Icon(PhosphorIconsRegular.plus, size: 14, color: AppColors.secondary),
                        label: const Text('Manage', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (addresses.isEmpty)
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('No shipping address found', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 12),
                              PrimaryButton(
                                text: 'ADD SHIPPING ADDRESS',
                                isFullWidth: false,
                                height: 36,
                                onPressed: () {
                                  context.push('/shop/addresses');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final addr = addresses[index];
                        final isSelected = _selectedAddressId == addr.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedAddressId = addr.id);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.secondary : AppColors.border,
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: CustomCard(
                              backgroundColor: isSelected ? Colors.grey.shade50 : AppColors.cardBackground,
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? PhosphorIconsFill.radioButton : PhosphorIconsRegular.circle,
                                    color: isSelected ? AppColors.secondary : AppColors.neutral,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr.label.toUpperCase(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                            if (addr.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('DEFAULT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${addr.street}, ${addr.area}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          '${addr.city} - ${addr.pincode}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // 2. Payment Method Section
                  const Text(
                    'PAYMENT METHOD',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Pay with cash or card upon delivery'),
                          value: 'cod',
                          groupValue: _paymentMethod,
                          activeColor: AppColors.secondary,
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(),
                        RadioListTile<String>(
                          title: const Text('Mock Online Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Simulate UPI / Card payment gateway'),
                          value: 'online',
                          groupValue: _paymentMethod,
                          activeColor: AppColors.secondary,
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Bill Summary Section
                  const Text(
                    'BILL DETAILS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    child: Column(
                      children: [
                        _buildSummaryRow('Cart Subtotal', '₹${shopState.cartSubtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Delivery Fee', shopState.cartDeliveryFee == 0 ? 'FREE' : '₹${shopState.cartDeliveryFee.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax (GST 5%)', '₹${shopState.cartTax.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        _buildSummaryRow('Amount Payable', '₹${shopState.cartTotal.toStringAsFixed(2)}', isBold: true, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: 'PLACE ORDER (₹${shopState.cartTotal.toInt()})',
                    onPressed: (addresses.isEmpty || shopState.cart.isEmpty) ? null : _placeOrder,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double size = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: size,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: size,
          ),
        ),
      ],
    );
  }
}
