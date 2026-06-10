import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../models/saved_address_model.dart';
import '../services/address_storage_service.dart';
import '../theme/theme.dart';
import 'saved_addresses_screen.dart';
import '../providers/address_provider.dart';

// ══════════════════════════════════════════════════════════════
//  Address Type Enum
// ══════════════════════════════════════════════════════════════
enum AddressType { home, work, other }

extension AddressTypeExt on AddressType {
  String get label {
    switch (this) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AddressType.home:
        return Icons.home_rounded;
      case AddressType.work:
        return Icons.work_rounded;
      case AddressType.other:
        return Icons.location_on_rounded;
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  Add Delivery Address Screen
// ══════════════════════════════════════════════════════════════
class AddDeliveryAddressScreen extends StatefulWidget {
  /// Pre-filled values from the map screen (optional)
  final String? mapAddress;
  final String? mapShortName;

  const AddDeliveryAddressScreen({
    super.key,
    this.mapAddress,
    this.mapShortName,
  });

  @override
  State<AddDeliveryAddressScreen> createState() =>
      _AddDeliveryAddressScreenState();
}

class _AddDeliveryAddressScreenState extends State<AddDeliveryAddressScreen>
    with TickerProviderStateMixin {
  // ── Form key ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────
  late final TextEditingController _flatCtrl;
  late final TextEditingController _societyCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _landmarkCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  // ── Focus nodes ───────────────────────────────────────────────
  final _flatFocus    = FocusNode();
  final _societyFocus = FocusNode();
  final _areaFocus    = FocusNode();
  final _cityFocus    = FocusNode();
  final _stateFocus   = FocusNode();
  final _pincodeFocus = FocusNode();
  final _landmarkFocus= FocusNode();
  final _nameFocus    = FocusNode();
  final _phoneFocus   = FocusNode();
  final _labelFocus   = FocusNode();

  // ── State ─────────────────────────────────────────────────────
  AddressType _selectedType = AddressType.home;
  bool _isDefault = false;
  bool _isSaving  = false;

  // ── Animation ─────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _flatCtrl     = TextEditingController();
    _societyCtrl  = TextEditingController();
    _areaCtrl     = TextEditingController(text: widget.mapShortName ?? '');
    _cityCtrl     = TextEditingController();
    _stateCtrl    = TextEditingController();
    _pincodeCtrl  = TextEditingController();
    _labelCtrl    = TextEditingController();
    _landmarkCtrl = TextEditingController();
    _nameCtrl     = TextEditingController();
    _phoneCtrl    = TextEditingController();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in [
      _flatCtrl, _societyCtrl, _areaCtrl, _cityCtrl, _stateCtrl,
      _pincodeCtrl, _labelCtrl, _landmarkCtrl, _nameCtrl, _phoneCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _flatFocus, _societyFocus, _areaFocus, _cityFocus, _stateFocus,
      _pincodeFocus, _landmarkFocus, _nameFocus, _phoneFocus, _labelFocus,
    ]) {
      f.dispose();
    }
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final label = _selectedType == AddressType.other ? _labelCtrl.text.trim() : _selectedType.label;
      final encodedStreet = [
        _flatCtrl.text.trim(),
        _societyCtrl.text.trim(),
        _landmarkCtrl.text.trim(),
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _stateCtrl.text.trim(),
      ].join('|');

      final success = await context.read<AddressProvider>().addAddress({
        'label': label.isNotEmpty ? label : 'Other',
        'street': encodedStreet,
        'area': _areaCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'isDefault': _isDefault,
      });

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success != null) {
        _snack('Address saved successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        // Navigate to Saved Addresses screen — replaces this screen in stack
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => SavedAddressesScreen(
              mapAddress:   widget.mapAddress,
              mapShortName: widget.mapShortName,
            ),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      } else {
        _snack('Failed to save address. Please try again.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Failed to save address. Please try again.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
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
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: error ? const Color(0xFFEF4444) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    children: [
                      // ── Map Pin Preview ─────────────────────
                      if (widget.mapAddress != null) ...[
                        _buildMapPinCard(),
                        const SizedBox(height: 20),
                      ],

                      // ── Address Type ────────────────────────
                      _buildSectionLabel('Address Type'),
                      const SizedBox(height: 12),
                      _buildAddressTypeSelector(),
                      const SizedBox(height: 24),

                      // ── Address Details ─────────────────────
                      _buildSectionLabel('Address Details'),
                      const SizedBox(height: 12),
                      _buildCard(children: [
                        _buildField(
                          controller: _flatCtrl,
                          focusNode: _flatFocus,
                          nextFocus: _societyFocus,
                          label: 'Flat / House No. / Floor',
                          hint: 'e.g. 4B, 3rd Floor',
                          icon: Icons.home_work_rounded,
                          required: true,
                        ),
                        _divider(),
                        _buildField(
                          controller: _societyCtrl,
                          focusNode: _societyFocus,
                          nextFocus: _areaFocus,
                          label: 'Building / Society Name',
                          hint: 'e.g. Green Meadows Apartments',
                          icon: Icons.apartment_rounded,
                        ),
                        _divider(),
                        _buildField(
                          controller: _landmarkCtrl,
                          focusNode: _landmarkFocus,
                          nextFocus: _areaFocus,
                          label: 'Landmark (Optional)',
                          hint: 'e.g. Near City Mall',
                          icon: Icons.place_rounded,
                        ),
                        _divider(),
                        _buildField(
                          controller: _areaCtrl,
                          focusNode: _areaFocus,
                          nextFocus: _cityFocus,
                          label: 'Area / Locality / Sector',
                          hint: 'e.g. Banjara Hills',
                          icon: Icons.location_city_rounded,
                          required: true,
                        ),
                        _divider(),
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: _buildField(
                              controller: _cityCtrl,
                              focusNode: _cityFocus,
                              nextFocus: _stateFocus,
                              label: 'City',
                              hint: 'Hyderabad',
                              icon: Icons.location_on_rounded,
                              required: true,
                              noDivider: true,
                            ),
                          ),
                          Container(width: 1, height: 64, color: const Color(0xFFEEF0F4)),
                          Expanded(
                            flex: 2,
                            child: _buildField(
                              controller: _pincodeCtrl,
                              focusNode: _pincodeFocus,
                              nextFocus: _stateFocus,
                              label: 'Pincode',
                              hint: '500034',
                              icon: Icons.pin_rounded,
                              required: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              noDivider: true,
                            ),
                          ),
                        ]),
                        _divider(),
                        _buildField(
                          controller: _stateCtrl,
                          focusNode: _stateFocus,
                          nextFocus: _nameFocus,
                          label: 'State',
                          hint: 'Telangana',
                          icon: Icons.map_rounded,
                          required: true,
                          noDivider: true,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Contact Info ────────────────────────
                      _buildSectionLabel('Contact Details'),
                      const SizedBox(height: 4),
                      Text(
                        'For smooth delivery coordination',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(children: [
                        _buildField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _phoneFocus,
                          label: 'Receiver\'s Name',
                          hint: 'Full name',
                          icon: Icons.person_rounded,
                          required: true,
                        ),
                        _divider(),
                        _buildField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          nextFocus: _labelFocus,
                          label: 'Mobile Number',
                          hint: '9XXXXXXXXX',
                          icon: Icons.phone_rounded,
                          required: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          noDivider: true,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Custom Label ────────────────────────
                      if (_selectedType == AddressType.other) ...[
                        _buildSectionLabel('Custom Label'),
                        const SizedBox(height: 12),
                        _buildCard(children: [
                          _buildField(
                            controller: _labelCtrl,
                            focusNode: _labelFocus,
                            label: 'Label Name',
                            hint: 'e.g. Gym, Parents\' Home',
                            icon: Icons.label_rounded,
                            noDivider: true,
                          ),
                        ]),
                        const SizedBox(height: 24),
                      ],

                      // ── Set as Default ──────────────────────
                      _buildDefaultToggle(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildSaveButton(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: topPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textDark, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Add Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress steps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                _buildStep(1, 'Location', true, false),
                _buildStepLine(true),
                _buildStep(2, 'Details', true, true),
                _buildStepLine(false),
                _buildStep(3, 'Confirm', false, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int n, String label, bool done, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: done || active
                ? const LinearGradient(
              colors: [Color(0xFF34D399), AppTheme.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: done || active ? null : const Color(0xFFE8ECF2),
            shape: BoxShape.circle,
            boxShadow: done || active
                ? [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Icon(
            done && !active ? Icons.check_rounded : Icons.circle,
            color: done || active ? Colors.white : const Color(0xFFBFC9D6),
            size: done && !active ? 15 : 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? AppTheme.primaryGreen
                : done
                ? AppTheme.textMedium
                : const Color(0xFFBFC9D6),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool filled) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 2,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
              colors: [Color(0xFF34D399), AppTheme.primaryGreen])
              : null,
          color: filled ? null : const Color(0xFFE8ECF2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MAP PIN PREVIEW CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildMapPinCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.08),
            AppTheme.primaryGreen.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pin dropped on map',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.mapAddress ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded,
                color: AppTheme.primaryGreen, size: 22),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Change on map',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ADDRESS TYPE SELECTOR
  // ══════════════════════════════════════════════════════════════
  Widget _buildAddressTypeSelector() {
    return Row(
      children: AddressType.values.map((type) {
        final selected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedType = type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: type != AddressType.other ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                  colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFE2E8F2),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
                    : [
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    color: selected ? Colors.white : AppTheme.textMedium,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  DEFAULT TOGGLE
  // ══════════════════════════════════════════════════════════════
  Widget _buildDefaultToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isDefault = !_isDefault);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isDefault
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: _isDefault
                        ? AppTheme.primaryGreen
                        : const Color(0xFFBFC9D6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set as Default Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automatically used for future orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: _isDefault
                        ? const LinearGradient(
                      colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                    )
                        : null,
                    color: _isDefault ? null : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _isDefault
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SAVE BUTTON (bottom nav)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSaveButton() {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
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
              colors: [
                Color(0xFF34D399),
                AppTheme.primaryGreen,
                AppTheme.darkGreen,
              ],
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
              onTap: _isSaving ? null : _onSave,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.15),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Save Delivery Address',
                      style: TextStyle(
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
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF4), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 0, color: Color(0xFFF0F3F7));

  Widget _buildField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    bool noDivider = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction:
      nextFocus != null ? TextInputAction.next : TextInputAction.done,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 14.5,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w500,
      ),
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          color: AppTheme.textMedium,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontSize: 13.5,
          color: AppTheme.textLight.withOpacity(0.7),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 18, color: AppTheme.textMedium),
        ),
        prefixIconConstraints: const BoxConstraints(),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }
}