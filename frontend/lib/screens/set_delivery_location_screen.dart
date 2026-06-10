import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../theme/theme.dart';
import '../models/saved_address_model.dart';
import '../services/address_storage_service.dart';
import 'add_delivery_address_screen.dart';
import 'saved_addresses_screen.dart';

// ══════════════════════════════════════════════════════════════
//  Model
// ══════════════════════════════════════════════════════════════
class DeliveryAddress {
  final String shortName;
  final String fullAddress;
  final LatLng coordinates;
  final double? distanceKm;

  const DeliveryAddress({
    required this.shortName,
    required this.fullAddress,
    required this.coordinates,
    this.distanceKm,
  });
}

// ══════════════════════════════════════════════════════════════
//  Main Screen
// ══════════════════════════════════════════════════════════════
class SetDeliveryLocationScreen extends StatefulWidget {
  const SetDeliveryLocationScreen({super.key});

  @override
  State<SetDeliveryLocationScreen> createState() =>
      _SetDeliveryLocationScreenState();
}

class _SetDeliveryLocationScreenState extends State<SetDeliveryLocationScreen>
    with SingleTickerProviderStateMixin {
  // ── Map ──────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  LatLng _pinLocation = const LatLng(17.6868, 83.0074);

  // ── State ────────────────────────────────────────────────────
  bool _isLoadingLocation = false;
  bool _isGeocoding = false;
  bool _isDragging = false;
  bool _showTooltip = true;
  DeliveryAddress? _resolvedAddress;
  LatLng? _currentUserLocation;

  // ── Search ───────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_Suggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;
  Timer? _dragTimer;

  // ── Pin pulse ─────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _searchFocus.addListener(() => setState(() {}));
    // Reverse geocode default pin immediately so card shows something
    _reverseGeocode(_pinLocation);
    // Then silently try to jump to real GPS location
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGpsOnStartup());
  }

  Future<void> _initGpsOnStartup() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      // Fast: try last known first
      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) return; // don't block startup with slow GPS fetch
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentUserLocation = loc;
        _pinLocation = loc;
      });
      _mapController.move(loc, 16.5);
      await _reverseGeocode(loc);
    } catch (_) {
      // Silent — user can tap button for full GPS fetch
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _dragTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  Geocoding
  // ══════════════════════════════════════════════════════════════
  Future<void> _reverseGeocode(LatLng pt) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final res = await http
          .get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
              '?lat=${pt.latitude}&lon=${pt.longitude}'
              '&format=json&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'HappyBowlApp/1.0',
          'Accept-Language': 'en',
        },
      )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? {};
        final shortName = (addr['suburb'] ??
            addr['neighbourhood'] ??
            addr['city_district'] ??
            addr['town'] ??
            addr['city'] ??
            'Location') as String;
        final parts = [
          addr['road'],
          addr['suburb'] ?? addr['neighbourhood'],
          addr['city'] ?? addr['town'] ?? addr['village'],
          addr['state'],
          addr['postcode'],
        ].whereType<String>().where((s) => s.isNotEmpty).toList();
        double? dist;
        if (_currentUserLocation != null) {
          dist = const Distance()
              .as(LengthUnit.Kilometer, _currentUserLocation!, pt);
        }
        setState(() {
          _resolvedAddress = DeliveryAddress(
            shortName: shortName,
            fullAddress: parts.join(', '),
            coordinates: pt,
            distanceKm: dist,
          );
        });
      } else {
        _fallback(pt);
      }
    } catch (_) {
      _fallback(pt);
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _fallback(LatLng p) {
    if (!mounted) return;
    setState(() {
      _resolvedAddress = DeliveryAddress(
        shortName: 'Selected Location',
        fullAddress:
        '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
        coordinates: p,
      );
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  Map Events
  // ══════════════════════════════════════════════════════════════
  void _onMapPositionChanged(MapCamera cam, bool hasGesture) {
    if (!hasGesture) return;
    _dragTimer?.cancel();
    setState(() {
      _isDragging = true;
      _showTooltip = false;
      _showSuggestions = false;
      _pinLocation = cam.center;
    });
    _searchFocus.unfocus();
    _dragTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isDragging = false);
      _reverseGeocode(_pinLocation);
    });
  }

  void _onMapTap(TapPosition _, LatLng pt) {
    HapticFeedback.lightImpact();
    _dragTimer?.cancel();
    setState(() {
      _pinLocation = pt;
      _isDragging = false;
      _showTooltip = false;
      _showSuggestions = false;
    });
    _mapController.move(pt, _mapController.camera.zoom);
    _reverseGeocode(pt);
    _searchFocus.unfocus();
  }

  // ══════════════════════════════════════════════════════════════
  //  GPS
  // ══════════════════════════════════════════════════════════════
  Future<void> _useCurrentLocation() async {
    HapticFeedback.mediumImpact();
    _searchFocus.unfocus();
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _showSuggestions = false;
    });
    try {
      // ── Step 1: GPS service enabled? ──────────────────────────
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        // Prompt user to turn on location, then re-check
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) _snack('GPS is off. Please enable Location Services.', error: true);
          return;
        }
      }

      // ── Step 2: Permission ────────────────────────────────────
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) _showPermDialog();
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) _snack('Location permission denied.', error: true);
        return;
      }

      // ── Step 3: Try last known first (instant) ────────────────
      Position? pos = await Geolocator.getLastKnownPosition();

      // ── Step 4: Get fresh position with platform settings ────
      if (pos == null) {
        final LocationSettings settings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          settings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: false,
            timeLimit: const Duration(seconds: 15),
          );
        } else if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          settings = AppleSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
            activityType: ActivityType.other,
            pauseLocationUpdatesAutomatically: false,
          );
        } else {
          settings = const LocationSettings(
            accuracy: LocationAccuracy.high,
          );
        }

        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: settings,
          );
        } catch (_) {
          // ── Step 5: Final fallback — legacy GPS manager ────────
          pos = await Geolocator.getCurrentPosition(
            locationSettings: defaultTargetPlatform == TargetPlatform.android
                ? AndroidSettings(
              accuracy: LocationAccuracy.medium,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 10),
            )
                : const LocationSettings(accuracy: LocationAccuracy.medium),
          );
        }
      }

      if (!mounted) return;
      if (pos == null) {
        _snack('Unable to determine location. Try again.', error: true);
        return;
      }

      final loc = LatLng(pos.latitude, pos.longitude);
      _dragTimer?.cancel();
      setState(() {
        _currentUserLocation = loc;
        _pinLocation = loc;
        _isDragging = false;
        _showTooltip = false;
        _showSuggestions = false;
      });
      _mapController.move(loc, 16.5);
      await _reverseGeocode(loc);
    } on TimeoutException {
      if (mounted) _snack('Location timed out. Move outdoors & try again.', error: true);
    } on LocationServiceDisabledException {
      if (mounted) _snack('Location Services are disabled.', error: true);
    } on PermissionDeniedException {
      if (mounted) _snack('Location permission denied.', error: true);
    } catch (e) {
      if (mounted) _snack('Location error. Check GPS & try again.', error: true);
      // ignore: avoid_print
      debugPrint('Location error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Search
  // ══════════════════════════════════════════════════════════════
  void _onSearchChanged(String q) {
    setState(() {});
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final res = await http
          .get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search'
              '?q=${Uri.encodeComponent(q)}&format=json&limit=8&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'HappyBowlApp/1.0',
          'Accept-Language': 'en',
        },
      )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = list.map((e) {
            final a = (e['address'] as Map<String, dynamic>?) ?? {};
            final suburb =
            (a['suburb'] ?? a['neighbourhood'] ?? a['city_district'] ?? '')
            as String;
            final city =
            (a['city'] ?? a['town'] ?? a['village'] ?? '') as String;
            final state = (a['state'] ?? '') as String;
            final country = (a['country'] ?? '') as String;
            final shortName = suburb.isNotEmpty
                ? suburb
                : city.isNotEmpty
                ? city
                : (e['display_name'] as String).split(',').first.trim();
            final road = (a['road'] ?? '') as String;
            final subParts = [
              if (road.isNotEmpty) road,
              if (city.isNotEmpty) city,
              if (state.isNotEmpty) state,
              if (country.isNotEmpty) country,
            ];
            return _Suggestion(
              shortName: shortName,
              subLine: subParts.take(3).join(', '),
              lat: double.parse(e['lat'] as String),
              lon: double.parse(e['lon'] as String),
            );
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {/* silent */} finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _pickSuggestion(_Suggestion s) {
    HapticFeedback.selectionClick();
    final loc = LatLng(s.lat, s.lon);
    _dragTimer?.cancel();
    setState(() {
      _pinLocation = loc;
      _isDragging = false;
      _showTooltip = false;
      _showSuggestions = false;
      _searchCtrl.text = s.shortName;
    });
    _mapController.move(loc, 15.5);
    _reverseGeocode(loc);
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _isSearching = false;
    });
  }

  void _showPermDialog() {
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permission',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Location is permanently denied.\nEnable it from App Settings.',
          style: TextStyle(color: AppTheme.textMedium, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMedium))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
        error ? const Color(0xFFEF4444) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        // Above bottom panel
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
  }

  void _onConfirm() {
    if (_resolvedAddress == null || _isGeocoding) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _resolvedAddress);
  }

  Future<void> _onAddAddress() async {
    if (_resolvedAddress == null || _isGeocoding) return;
    HapticFeedback.mediumImpact();

    // Check if any saved addresses already exist
    final saved = await AddressStorageService.getAll();
    if (!mounted) return;

    if (saved.isNotEmpty) {
      // ── Has saved addresses → go to Saved Addresses screen ──
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => SavedAddressesScreen(
            mapAddress:   _resolvedAddress!.fullAddress,
            mapShortName: _resolvedAddress!.shortName,
          ),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      );
    } else {
      // ── No saved addresses → go directly to Add Address ─────
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => AddDeliveryAddressScreen(
            mapAddress:   _resolvedAddress!.fullAddress,
            mapShortName: _resolvedAddress!.shortName,
          ),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  //
  //  KEY FIX: resizeToAvoidBottomInset: true  →  Scaffold
  //  automatically shrinks the body when keyboard opens.
  //  The bottom panel is OUTSIDE the scrollable/map area so it
  //  stays pinned to the visual bottom. Only the map shrinks.
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // FALSE → keyboard overlaps the body; bottom panel hides behind keyboard.
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── 1. TOP BAR (fixed, never scrolls) ─────────────
            _TopBar(
              topPad: topPad,
              searchCtrl: _searchCtrl,
              searchFocus: _searchFocus,
              isSearching: _isSearching,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              onBack: () => Navigator.pop(context),
              onSubmitted: (_) {
                if (_suggestions.isNotEmpty) {
                  _pickSuggestion(_suggestions.first);
                }
              },
            ),

            // ── 2. MIDDLE (map + overlays, shrinks with keyboard)
            Expanded(
              child: Stack(
                children: [
                  // ── MAP ───────────────────────────────────────
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _pinLocation,
                        initialZoom: 15.0,
                        minZoom: 4,
                        maxZoom: 19,
                        onTap: _onMapTap,
                        onPositionChanged: _onMapPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.healthxworld.app',
                          maxZoom: 19,
                        ),
                      ],
                    ),
                  ),

                  // ── CENTER PIN (hidden while suggestions open) ─
                  if (!_showSuggestions)
                    _buildCenterPin(),

                  // ── "Use my current location" pill ────────────
                  // Sits on map, above the bottom panel.
                  // Hidden when suggestions are open.
                  if (!_showSuggestions)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildLocationPill()),
                    ),

                  // ── SUGGESTIONS (white card, below search bar,
                  //    map barely visible, ref Image 2 & 6 exact) ─
                  if (_showSuggestions)
                    _buildSuggestionsCard(),
                ],
              ),
            ),

            // ── 3. BOTTOM PANEL — animates in/out smoothly
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              child: (keyboardOpen || _showSuggestions)
                  ? const SizedBox.shrink()
                  : AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                opacity: (keyboardOpen || _showSuggestions) ? 0.0 : 1.0,
                child: _buildBottomPanel(bottomPad),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  CENTER PIN
  // ══════════════════════════════════════════════════════════════
  Widget _buildCenterPin() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = Curves.easeOut.transform(_pulseCtrl.value);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tooltip
              if (_showTooltip)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Place pin on the exact location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Pin with pulse
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!_isDragging)
                    Opacity(
                      opacity: (1 - pulse) * 0.45,
                      child: Container(
                        width: 22 + 42 * pulse,
                        height: 22 + 42 * pulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withOpacity(0.22),
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 52,
                    height: 52,
                    transform: Matrix4.translationValues(
                        0, _isDragging ? -12 : 0, 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF34D399),
                          AppTheme.primaryGreen,
                          AppTheme.darkGreen,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(
                              _isDragging ? 0.5 : 0.35),
                          blurRadius: _isDragging ? 28 : 16,
                          offset: Offset(0, _isDragging ? 12 : 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
              // Shadow dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _isDragging ? 8 : 16,
                height: _isDragging ? 3 : 5,
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(_isDragging ? 0.08 : 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  LOCATION PILL (on map)
  // ══════════════════════════════════════════════════════════════
  Widget _buildLocationPill() {
    return GestureDetector(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoadingLocation
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryGreen,
              ),
            )
                : const Icon(Icons.my_location_rounded,
                color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              _isLoadingLocation
                  ? 'Getting location...'
                  : 'Use my current location',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SUGGESTIONS CARD
  //  Ref Image 2 & 6: white card, map shows through edges,
  //  plain list rows, no full-screen overlay.
  // ══════════════════════════════════════════════════════════════
  Widget _buildSuggestionsCard() {
    return Positioned.fill(
      // Fill entire stack so the list is scrollable and
      // sits flush above the keyboard (no gap, no overlap).
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          children: [
            // Suggestion rows
            ..._suggestions.map((s) => _SuggestionRow(
              suggestion: s,
              onTap: () => _pickSuggestion(s),
            )),

            // Divider + "Use my current location" row
            const Divider(height: 1, color: Color(0xFFEEF0F2)),
            Material(
              color: Colors.white,
              child: InkWell(
                onTap: _isLoadingLocation ? null : _useCurrentLocation,
                splashColor: AppTheme.lightGreen.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isLoadingLocation
                            ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                            : const Icon(Icons.my_location_rounded,
                            color: AppTheme.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _isLoadingLocation
                            ? 'Getting location...'
                            : 'Use my current location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BOTTOM PANEL
  //  Lives in the Column (not Stack) so it naturally stays
  //  above the keyboard when resizeToAvoidBottomInset: true
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomPanel(double bottomPad) {
    final addr = _resolvedAddress;
    final canConfirm = addr != null && !_isGeocoding;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3EA),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPad + 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Row(
                  children: [
                    const Text(
                      'DELIVER TO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMedium,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isGeocoding)
                      const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: _AddressCard(
                    key: ValueKey(addr?.shortName ?? 'empty'),
                    address: addr,
                    onChangeTap: () => _searchFocus.requestFocus(),
                  ),
                ),

                const SizedBox(height: 12),

                // Confirm button
                _ConfirmButton(enabled: canConfirm, onTap: _onConfirm),
                const SizedBox(height: 10),
                _AddAddressButton(enabled: canConfirm, onTap: _onAddAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOP BAR
// ══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final double topPad;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmitted;

  const _TopBar({
    required this.topPad,
    required this.searchCtrl,
    required this.searchFocus,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final focused = searchFocus.hasFocus;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: topPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textDark, size: 20),
                  onPressed: onBack,
                ),
                const Text(
                  'Set Delivery Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: focused
                      ? AppTheme.primaryGreen
                      : const Color(0xFFE2E8F0),
                  width: focused ? 1.8 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: focused
                        ? AppTheme.primaryGreen.withOpacity(0.12)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: focused ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: searchCtrl,
                focusNode: searchFocus,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search area, street or landmark...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: isSearching
                      ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.search_rounded,
                    color: focused
                        ? AppTheme.primaryGreen
                        : AppTheme.textMedium,
                    size: 22,
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                    onPressed: onClear,
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: AppTheme.textMedium),
                    ),
                  )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SUGGESTION ROW
// ══════════════════════════════════════════════════════════════
class _SuggestionRow extends StatelessWidget {
  final _Suggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionRow({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            splashColor: AppTheme.lightGreen.withOpacity(0.25),
            highlightColor: AppTheme.lightGreen.withOpacity(0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // Pin icon — grey circle like reference
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.textMedium,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suggestion.shortName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (suggestion.subLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            suggestion.subLine,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.north_west_rounded,
                      size: 15, color: AppTheme.textLight),
                ],
              ),
            ),
          ),
        ),
        const Divider(
            height: 1, indent: 62, color: Color(0xFFEEF0F2)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ADDRESS CARD
// ══════════════════════════════════════════════════════════════
class _AddressCard extends StatelessWidget {
  final DeliveryAddress? address;
  final VoidCallback onChangeTap;

  const _AddressCard({
    super.key,
    required this.address,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final addr = address;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: const Color(0xFFE8EDF4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addr?.shortName ?? 'Detecting...',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (addr != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          addr.fullAddress,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMedium,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChangeTap();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (addr?.distanceKm != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route_rounded,
                      size: 13, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5),
                      children: [
                        TextSpan(
                          text:
                          '${addr!.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: '  from your current location',
                          style:
                          TextStyle(color: AppTheme.textMedium),
                        ),
                      ],
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

// ══════════════════════════════════════════════════════════════
//  CONFIRM BUTTON
// ══════════════════════════════════════════════════════════════
class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ConfirmButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF34D399),
              AppTheme.primaryGreen,
              AppTheme.darkGreen,
            ],
            stops: [0.0, 0.5, 1.0],
          )
              : LinearGradient(
              colors: [Colors.grey.shade200, Colors.grey.shade200]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.34),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withOpacity(0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  enabled
                      ? Icons.check_circle_rounded
                      : Icons.location_searching_rounded,
                  color: enabled ? Colors.white : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  enabled
                      ? 'Confirm Delivery Location'
                      : 'Detecting location...',
                  style: TextStyle(
                    color:
                    enabled ? Colors.white : Colors.grey.shade400,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Suggestion Model
// ══════════════════════════════════════════════════════════════
class _Suggestion {
  final String shortName;
  final String subLine;
  final double lat;
  final double lon;

  const _Suggestion({
    required this.shortName,
    required this.subLine,
    required this.lat,
    required this.lon,
  });
}
// ══════════════════════════════════════════════════════════════
//  ADD ADDRESS BUTTON  (navigates to AddDeliveryAddressScreen)
// ══════════════════════════════════════════════════════════════
class _AddAddressButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddAddressButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? AppTheme.lightGreen : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? AppTheme.primaryGreen.withOpacity(0.35)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppTheme.primaryGreen.withOpacity(0.12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_location_alt_rounded,
                  color: enabled
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Address Details',
                  style: TextStyle(
                    color: enabled
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: enabled
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade400,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}