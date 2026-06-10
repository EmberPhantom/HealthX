// lib/models/saved_address_model.dart
// ══════════════════════════════════════════════════════════════
//  SavedAddress — persisted locally via SharedPreferences
// ══════════════════════════════════════════════════════════════

class SavedAddress {
  final String id;
  final String addressType; // 'home' | 'work' | 'other'
  final String customLabel; // only used when type == 'other'
  final String flat;
  final String society;
  final String landmark;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String receiverName;
  final String phone;
  final String? mapAddress;   // raw string from map pin
  final bool isDefault;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.addressType,
    required this.customLabel,
    required this.flat,
    required this.society,
    required this.landmark,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.receiverName,
    required this.phone,
    this.mapAddress,
    required this.isDefault,
    required this.createdAt,
  });

  /// Human-readable type label
  String get typeLabel {
    if (addressType == 'home') return 'Home';
    if (addressType == 'work') return 'Work';
    return customLabel.isNotEmpty ? customLabel : 'Other';
  }

  /// Short one-line address for list tiles
  String get shortLine => [flat, society, area].where((s) => s.isNotEmpty).join(', ');

  /// Full address block
  String get fullLine {
    final parts = [flat, society, landmark, area, city, state, pincode]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  SavedAddress copyWith({bool? isDefault}) => SavedAddress(
    id: id,
    addressType: addressType,
    customLabel: customLabel,
    flat: flat,
    society: society,
    landmark: landmark,
    area: area,
    city: city,
    state: state,
    pincode: pincode,
    receiverName: receiverName,
    phone: phone,
    mapAddress: mapAddress,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'addressType': addressType,
    'customLabel': customLabel,
    'flat': flat,
    'society': society,
    'landmark': landmark,
    'area': area,
    'city': city,
    'state': state,
    'pincode': pincode,
    'receiverName': receiverName,
    'phone': phone,
    'mapAddress': mapAddress,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
    id: j['id'] as String,
    addressType: j['addressType'] as String,
    customLabel: (j['customLabel'] as String?) ?? '',
    flat: (j['flat'] as String?) ?? '',
    society: (j['society'] as String?) ?? '',
    landmark: (j['landmark'] as String?) ?? '',
    area: (j['area'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
    state: (j['state'] as String?) ?? '',
    pincode: (j['pincode'] as String?) ?? '',
    receiverName: (j['receiverName'] as String?) ?? '',
    phone: (j['phone'] as String?) ?? '',
    mapAddress: j['mapAddress'] as String?,
    isDefault: (j['isDefault'] as bool?) ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
        DateTime.now(),
  );
}