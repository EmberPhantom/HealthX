import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isSearchVisible = false;
  bool _isLoadingSearch = false;
  List<NominatimResult> _searchResults = [];

  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090); // Delhi
  static const double _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), _defaultZoom);
        }
      }
    } catch (_) {
      // GPS unavailable or timeout — stays at default fallback
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchResults = [];
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchNominatim(query.trim());
    });
  }

  Future<void> _searchNominatim(String query) async {
    setState(() => _isLoadingSearch = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'com.healthxworld.app',
      });

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as List;
      if (!mounted) return;

      setState(() {
        _searchResults = data
            .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      // Search failed — silently ignore
    } finally {
      if (mounted) setState(() => _isLoadingSearch = false);
    }
  }

  void _onSearchResultTap(NominatimResult result) {
    _mapController.move(LatLng(result.lat, result.lon), 16.0);
    setState(() {
      _isSearchVisible = false;
      _searchResults = [];
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  void _onConfirm() {
    final center = _mapController.camera.center;
    Navigator.pop(context, LatLng(center.latitude, center.longitude));
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Pick Delivery Location',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? PhosphorIconsRegular.x : PhosphorIconsRegular.magnifyingGlass,
              color: AppColors.secondary,
              size: 22,
            ),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: _isSearchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search area, city, landmark...',
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
                          suffixIcon: _isLoadingSearch
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'location',
            backgroundColor: AppColors.primary,
            onPressed: _getCurrentLocation,
            child: const Icon(PhosphorIconsRegular.crosshair, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'confirm',
            backgroundColor: AppColors.secondary,
            onPressed: _onConfirm,
            child: const Icon(PhosphorIconsRegular.check, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // ─── Map ──────────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            onMapEvent: (_) {
              if (_isSearchVisible && _searchResults.isNotEmpty) {
                setState(() => _searchResults = []);
              }
            },
          ),
          children: [
            TileLayer(
              tileProvider: FMTCTileProvider.allStores(
                allStoresStrategy: BrowseStoreStrategy.readUpdateCreate,
              ),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.healthxworld.app',
            ),
          ],
        ),

        // ─── Center Pin ───────────────────────────────────────────────────────
        IgnorePointer(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pin shadow
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 2),
                // Pin icon
                Icon(
                  PhosphorIconsRegular.mapPin,
                  color: AppColors.error,
                  size: 44,
                ),
              ],
            ),
          ),
        ),

        // ─── Search Results Dropdown ──────────────────────────────────────────
        if (_searchResults.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (_, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(PhosphorIconsRegular.mapPin, size: 20, color: AppColors.secondary),
                      title: Text(
                        result.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _onSearchResultTap(result),
                    );
                  },
                ),
              ),
            ),
          ),

        // ─── Bottom Instruction Bar ───────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.mapPin, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Drag the map to move the pin to your delivery location',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

class NominatimResult {
  final String displayName;
  final double lat;
  final double lon;
  final String? city;
  final String? area;
  final String? pincode;

  const NominatimResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.city,
    this.area,
    this.pincode,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    return NominatimResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '') ?? 0.0,
      city: address['city'] ?? address['town'] ?? address['village'],
      area: address['suburb'] ?? address['neighbourhood'] ?? address['residential'],
      pincode: address['postcode'],
    );
  }
}
