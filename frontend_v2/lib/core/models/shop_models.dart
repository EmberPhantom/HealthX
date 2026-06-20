import 'package:equatable/equatable.dart';

class ShopProduct extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int calories;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String emoji;
  final String category;
  final String type; // 'Regular' | 'ReadyToEat'
  final List<String> tags;
  final bool isVeg;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.emoji,
    required this.category,
    required this.type,
    required this.tags,
    required this.isVeg,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    return ShopProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      emoji: json['emoji'] ?? '🥗',
      category: json['category'] ?? '',
      type: json['type'] ?? 'Regular',
      tags: List<String>.from(json['tags'] ?? []),
      isVeg: json['isVeg'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'calories': calories,
    'rating': rating,
    'reviewCount': reviewCount,
    'imageUrl': imageUrl,
    'emoji': emoji,
    'category': category,
    'type': type,
    'tags': tags,
    'isVeg': isVeg,
  };

  @override
  List<Object?> get props => [
    id, name, description, price, calories, rating, reviewCount,
    imageUrl, emoji, category, type, tags, isVeg
  ];
}

class AddressModel extends Equatable {
  final String id;
  final String label; // 'Home', 'Work', 'Other'
  final String street;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] ?? json['id'] ?? '',
      label: json['label'] ?? 'Home',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'street': street,
    'area': area,
    'city': city,
    'pincode': pincode,
    'isDefault': isDefault,
  };

  @override
  List<Object?> get props => [id, label, street, area, city, pincode, isDefault];
}

class OrderItemModel extends Equatable {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      menuItemId: json['menuItemId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'name': name,
    'quantity': quantity,
    'price': price,
  };

  @override
  List<Object?> get props => [menuItemId, name, quantity, price];
}

class OrderModel extends Equatable {
  final String id;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String status;
  final String paymentMethod;
  final bool isPaid;
  final String? addressId;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    this.addressId,
    this.estimatedDelivery,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'placed',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      isPaid: json['isPaid'] ?? false,
      addressId: json['addressId'] is Map ? json['addressId']['_id'] : json['addressId'],
      estimatedDelivery: json['estimatedDelivery'] != null ? DateTime.tryParse(json['estimatedDelivery'])?.toLocal() : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'])?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'tax': tax,
    'total': total,
    'status': status,
    'paymentMethod': paymentMethod,
    'isPaid': isPaid,
    'addressId': addressId,
    'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, items, subtotal, deliveryFee, tax, total, status, paymentMethod,
    isPaid, addressId, estimatedDelivery, createdAt
  ];
}

class TrackingEvent extends Equatable {
  final String status;
  final DateTime timestamp;
  final String description;

  const TrackingEvent({
    required this.status,
    required this.timestamp,
    this.description = '',
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };

  @override
  List<Object?> get props => [status, timestamp, description];
}

class TrackingData extends Equatable {
  final String orderId;
  final String currentStatus;
  final DateTime? estimatedDelivery;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final double? driverLatitude;
  final double? driverLongitude;
  final List<TrackingEvent> timeline;

  const TrackingData({
    required this.orderId,
    required this.currentStatus,
    this.estimatedDelivery,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverLatitude,
    this.driverLongitude,
    this.timeline = const [],
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      orderId: json['orderId'] ?? json['_id'] ?? '',
      currentStatus: json['currentStatus'] ?? json['status'] ?? 'placed',
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'])?.toLocal()
          : null,
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      driverVehicle: json['driverVehicle'],
      driverLatitude: (json['driverLatitude'] as num?)?.toDouble(),
      driverLongitude: (json['driverLongitude'] as num?)?.toDouble(),
      timeline: (json['timeline'] as List? ?? [])
          .map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'currentStatus': currentStatus,
    'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    'driverName': driverName,
    'driverPhone': driverPhone,
    'driverVehicle': driverVehicle,
    'driverLatitude': driverLatitude,
    'driverLongitude': driverLongitude,
    'timeline': timeline.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    orderId, currentStatus, estimatedDelivery, driverName, driverPhone,
    driverVehicle, driverLatitude, driverLongitude, timeline,
  ];
}

class MealPlan extends Equatable {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String subtitle;
  final String priceSuffix;
  final String? badgeLabel;
  final String accentColor;
  final String btnColor;
  final bool isFeatured;
  final String tagIcon;
  final String cardBgColor;
  final String assetImagePath;
  final String destination;

  const MealPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.subtitle,
    required this.priceSuffix,
    this.badgeLabel,
    required this.accentColor,
    required this.btnColor,
    required this.isFeatured,
    required this.tagIcon,
    required this.cardBgColor,
    required this.assetImagePath,
    required this.destination,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['planName'] ?? json['name'] ?? '',
      price: json['price'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      subtitle: json['subtitle'] ?? '',
      priceSuffix: json['priceSuffix'] ?? '',
      badgeLabel: json['badgeLabel'],
      accentColor: json['accentColor'] ?? '0xFF059669',
      btnColor: json['btnColor'] ?? '0xFF059669',
      isFeatured: json['isFeatured'] ?? false,
      tagIcon: json['tagIcon'] ?? '',
      cardBgColor: json['cardBgColor'] ?? '0xFFECFDF5',
      assetImagePath: json['assetImagePath'] ?? '',
      destination: json['destination'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planName': name,
    'price': price,
    'imageUrl': imageUrl,
    'subtitle': subtitle,
    'priceSuffix': priceSuffix,
    'badgeLabel': badgeLabel,
    'accentColor': accentColor,
    'btnColor': btnColor,
    'isFeatured': isFeatured,
    'tagIcon': tagIcon,
    'cardBgColor': cardBgColor,
    'assetImagePath': assetImagePath,
    'destination': destination,
  };

  @override
  List<Object?> get props => [
    id, name, price, imageUrl, subtitle, priceSuffix, badgeLabel,
    accentColor, btnColor, isFeatured, tagIcon, cardBgColor, assetImagePath, destination
  ];
}
