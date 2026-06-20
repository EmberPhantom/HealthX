import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';
import 'map_picker_screen.dart';

class AddressManagementScreen extends ConsumerStatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  ConsumerState<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends ConsumerState<AddressManagementScreen> {
  void _showAddressForm({AddressModel? address}) {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: address?.label ?? 'Home');
    final streetController = TextEditingController(text: address?.street ?? '');
    final areaController = TextEditingController(text: address?.area ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final pincodeController = TextEditingController(text: address?.pincode ?? '');
    bool isDefault = address?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address == null ? 'ADD NEW ADDRESS' : 'EDIT ADDRESS',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 16),

                      // Label input (Home / Work etc)
                      DropdownButtonFormField<String>(
                        value: labelController.text,
                        decoration: const InputDecoration(labelText: 'Address Label', border: OutlineInputBorder()),
                        items: ['Home', 'Work', 'Other'].map((l) {
                          return DropdownMenuItem(value: l, child: Text(l));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => labelController.text = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Street Address
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(labelText: 'Flat / House No. / Street', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),

                      // Area / Locality
                      TextFormField(
                        controller: areaController,
                        decoration: InputDecoration(
                          labelText: 'Area / Colony / Landmark',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(PhosphorIconsRegular.mapPin, color: AppColors.secondary, size: 22),
                            tooltip: 'Pick on Map',
                            onPressed: () => _pickLocationOnMap(
                              setModalState,
                              labelController,
                              streetController,
                              areaController,
                              cityController,
                              pincodeController,
                            ),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),

                      // City & Pincode
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: pincodeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (val.trim().length != 6) return 'Must be 6 digits';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Is Default Toggle
                      CheckboxListTile(
                        title: const Text('Set as default shipping address', style: TextStyle(fontSize: 14)),
                        value: isDefault,
                        activeColor: AppColors.secondary,
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => isDefault = val);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      PrimaryButton(
                        text: address == null ? 'SAVE ADDRESS' : 'UPDATE ADDRESS',
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          HapticFeedback.lightImpact();
                          bool success;

                          if (address == null) {
                            success = await ref.read(shopProvider.notifier).addAddress(
                                  label: labelController.text.trim(),
                                  street: streetController.text.trim(),
                                  area: areaController.text.trim(),
                                  city: cityController.text.trim(),
                                  pincode: pincodeController.text.trim(),
                                  isDefault: isDefault,
                                );
                          } else {
                            success = await ref.read(shopProvider.notifier).editAddress(
                                  address.id,
                                  label: labelController.text.trim(),
                                  street: streetController.text.trim(),
                                  area: areaController.text.trim(),
                                  city: cityController.text.trim(),
                                  pincode: pincodeController.text.trim(),
                                  isDefault: isDefault,
                                );
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Address saved!' : 'Failed to save address'),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickLocationOnMap(
    StateSetter setModalState,
    TextEditingController labelCtrl,
    TextEditingController streetCtrl,
    TextEditingController areaCtrl,
    TextEditingController cityCtrl,
    TextEditingController pincodeCtrl,
  ) async {
    final picked = await Navigator.push<latlong2.LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (picked == null || !context.mounted) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        picked.latitude,
        picked.longitude,
      );
      if (placemarks.isNotEmpty && context.mounted) {
        final p = placemarks.first;
        setModalState(() {
          streetCtrl.text = (p.street ?? p.thoroughfare ?? streetCtrl.text);
          areaCtrl.text = (p.subLocality ?? p.locality ?? areaCtrl.text);
          cityCtrl.text = (p.locality ?? p.administrativeArea ?? cityCtrl.text);
          pincodeCtrl.text = (p.postalCode ?? pincodeCtrl.text);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not auto-fill address details. Please enter manually.'),
            backgroundColor: AppColors.neutral,
          ),
        );
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this shipping address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final success = await ref.read(shopProvider.notifier).removeAddress(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Address deleted' : 'Failed to delete address'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final addresses = shopState.addresses;

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
          'Saved Addresses',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: shopState.isLoading && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(shopProvider.notifier).fetchAddresses(),
              color: AppColors.primary,
              child: Column(
                children: [
                  Expanded(
                    child: addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'No shipping addresses logged yet.',
                              style: TextStyle(color: AppColors.neutral),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final addr = addresses[index];
                              return _buildAddressCard(addr);
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PrimaryButton(
                      text: 'ADD NEW ADDRESS',
                      onPressed: () => _showAddressForm(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard(AddressModel addr) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              addr.label.toLowerCase() == 'home'
                  ? PhosphorIconsRegular.house
                  : addr.label.toLowerCase() == 'work'
                      ? PhosphorIconsRegular.briefcase
                      : PhosphorIconsRegular.mapPin,
              color: AppColors.secondary,
              size: 20,
            ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    if (addr.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${addr.street}, ${addr.area}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${addr.city} - ${addr.pincode}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Card actions
                Row(
                  children: [
                    if (!addr.isDefault)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(shopProvider.notifier).makeAddressDefault(addr.id);
                        },
                        child: const Text('Set Default', style: TextStyle(color: AppColors.neutral, fontSize: 12)),
                      ),
                    TextButton(
                      onPressed: () => _showAddressForm(address: addr),
                      child: const Text('Edit', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.neutral, size: 18),
                      onPressed: () => _confirmDelete(addr.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
