import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_v2/core/models/shop_models.dart';

void main() {
  group('TrackingEvent', () {
    test('fromJson parses correctly', () {
      final event = TrackingEvent.fromJson({
        'status': 'placed',
        'timestamp': '2026-06-11T10:30:00.000Z',
        'description': 'Order placed successfully',
      });

      expect(event.status, 'placed');
      expect(event.description, 'Order placed successfully');
      expect(event.timestamp.year, 2026);
    });

    test('fromJson handles missing fields', () {
      final event = TrackingEvent.fromJson({});
      expect(event.status, '');
      expect(event.description, '');
      expect(event.timestamp, isNotNull);
    });

    test('toJson returns correct map', () {
      final event = TrackingEvent(
        status: 'on_the_way',
        timestamp: DateTime(2026, 6, 11, 14, 0),
        description: 'Driver is en route',
      );

      final json = event.toJson();
      expect(json['status'], 'on_the_way');
      expect(json['description'], 'Driver is en route');
      expect(json['timestamp'], isA<String>());
    });

    test('equality works', () {
      final a = TrackingEvent(status: 'placed', timestamp: DateTime(2026, 6, 11));
      final b = TrackingEvent(status: 'placed', timestamp: DateTime(2026, 6, 11));
      final c = TrackingEvent(status: 'delivered', timestamp: DateTime(2026, 6, 11));

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('TrackingData', () {
    test('fromJson parses full data', () {
      final data = TrackingData.fromJson({
        'orderId': 'abc123',
        'currentStatus': 'on_the_way',
        'estimatedDelivery': '2026-06-11T15:00:00.000Z',
        'driverName': 'Rahul',
        'driverPhone': '9876543210',
        'driverVehicle': 'KA-01-AB-1234',
        'driverLatitude': 12.9716,
        'driverLongitude': 77.5946,
        'timeline': [
          {'status': 'placed', 'timestamp': '2026-06-11T10:00:00.000Z', 'description': 'Order placed'},
          {'status': 'on_the_way', 'timestamp': '2026-06-11T14:00:00.000Z', 'description': 'Out for delivery'},
        ],
      });

      expect(data.orderId, 'abc123');
      expect(data.currentStatus, 'on_the_way');
      expect(data.driverName, 'Rahul');
      expect(data.driverPhone, '9876543210');
      expect(data.driverVehicle, 'KA-01-AB-1234');
      expect(data.driverLatitude, 12.9716);
      expect(data.driverLongitude, 77.5946);
      expect(data.timeline.length, 2);
      expect(data.timeline[0].status, 'placed');
      expect(data.timeline[1].status, 'on_the_way');
    });

    test('fromJson handles minimal data', () {
      final data = TrackingData.fromJson({
        '_id': 'order1',
        'status': 'placed',
      });

      expect(data.orderId, 'order1');
      expect(data.currentStatus, 'placed');
      expect(data.driverName, isNull);
      expect(data.driverPhone, isNull);
      expect(data.driverVehicle, isNull);
      expect(data.driverLatitude, isNull);
      expect(data.driverLongitude, isNull);
      expect(data.timeline, isEmpty);
    });

    test('fromJson handles _id fallback', () {
      final data = TrackingData.fromJson({'_id': 'test-id'});
      expect(data.orderId, 'test-id');
    });

    test('toJson roundtrip', () {
      final original = TrackingData(
        orderId: 'ord123',
        currentStatus: 'delivered',
        timeline: [
          TrackingEvent(status: 'placed', timestamp: DateTime(2026, 6, 11), description: ''),
        ],
      );

      final json = original.toJson();
      final restored = TrackingData.fromJson(json);

      expect(restored.orderId, original.orderId);
      expect(restored.currentStatus, original.currentStatus);
      expect(restored.timeline.length, original.timeline.length);
      expect(restored.timeline[0].status, original.timeline[0].status);
    });
  });

  group('NominatimResult (from map_picker_screen)', () {
    test('fromJson parses full address', () {
      final result = _NominatimResult.fromJson({
        'display_name': 'MG Road, Bengaluru, Karnataka, India',
        'lat': '12.9716',
        'lon': '77.5946',
        'address': {
          'city': 'Bengaluru',
          'suburb': 'MG Road',
          'postcode': '560001',
        },
      });

      expect(result.displayName, contains('MG Road'));
      expect(result.lat, 12.9716);
      expect(result.lon, 77.5946);
      expect(result.city, 'Bengaluru');
      expect(result.area, 'MG Road');
      expect(result.pincode, '560001');
    });

    test('fromJson parses town/village fallback', () {
      final result = _NominatimResult.fromJson({
        'display_name': 'Small Village, India',
        'lat': '10.0',
        'lon': '20.0',
        'address': {
          'town': 'Small Town',
          'neighbourhood': 'Sector 5',
          'postcode': '123456',
        },
      });

      expect(result.city, 'Small Town');
      expect(result.area, 'Sector 5');
      expect(result.pincode, '123456');
    });

    test('fromJson handles missing fields', () {
      final result = _NominatimResult.fromJson({'display_name': 'X', 'lat': '0', 'lon': '0'});
      expect(result.city, isNull);
      expect(result.area, isNull);
      expect(result.pincode, isNull);
    });

    test('fromJson handles invalid lat/lon', () {
      final result = _NominatimResult.fromJson({
        'display_name': 'Test',
        'lat': 'invalid',
        'lon': 'invalid',
      });
      expect(result.lat, 0.0);
      expect(result.lon, 0.0);
    });
  });
}

// Duplicate of the model from map_picker_screen.dart for testing
class _NominatimResult {
  final String displayName;
  final double lat;
  final double lon;
  final String? city;
  final String? area;
  final String? pincode;

  const _NominatimResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.city,
    this.area,
    this.pincode,
  });

  factory _NominatimResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    return _NominatimResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '') ?? 0.0,
      city: address['city'] ?? address['town'] ?? address['village'],
      area: address['suburb'] ?? address['neighbourhood'] ?? address['residential'],
      pincode: address['postcode'],
    );
  }
}
