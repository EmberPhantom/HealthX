class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final bool isPremium;
  final UserStats stats;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.isPremium,
    required this.stats,
  });
}

class UserStats {
  final int steps;
  final int caloriesBurned;
  final String sleepTime;
  final int waterGlasses;
  final int waterGoal;

  const UserStats({
    required this.steps,
    required this.caloriesBurned,
    required this.sleepTime,
    required this.waterGlasses,
    required this.waterGoal,
  });
}

class MenuItem {
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
  final List<String> tags;
  final bool isVeg;
  bool isFavorite;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.rating,
    this.reviewCount = 0,
    required this.imageUrl,
    this.emoji = '🥗',
    required this.category,
    this.tags = const [],
    this.isVeg = true,
    this.isFavorite = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      emoji: json['emoji'] ?? '🥗',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isVeg: json['isVeg'] ?? true,
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get subtotal => menuItem.price * quantity;
}

class MealPlan {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String? subtitle;
  final String? priceSuffix;
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
    this.subtitle,
    this.priceSuffix,
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
}

class DeliveryAddress {
  final String id;
  final String label;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $area, $city - $pincode';

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['_id'] ?? json['id'] ?? '',
      label: json['label'] ?? '',
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
}

class DeliveryPartner {
  final String name;
  final double rating;
  final int deliveries;
  final String avatarUrl;

  const DeliveryPartner({
    required this.name,
    required this.rating,
    required this.deliveries,
    required this.avatarUrl,
  });
}

enum OrderStatus { placed, preparing, outForDelivery, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final DeliveryAddress address;
  final String paymentMethod;
  final OrderStatus status;
  final DeliveryPartner? deliveryPartner;
  final DateTime createdAt;
  final DateTime estimatedDelivery;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.status,
    this.deliveryPartner,
    required this.createdAt,
    required this.estimatedDelivery,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    OrderStatus parsedStatus = OrderStatus.placed;
    switch (json['status']) {
      case 'placed':
        parsedStatus = OrderStatus.placed;
        break;
      case 'confirmed':
      case 'preparing':
        parsedStatus = OrderStatus.preparing;
        break;
      case 'on_the_way':
        parsedStatus = OrderStatus.outForDelivery;
        break;
      case 'delivered':
        parsedStatus = OrderStatus.delivered;
        break;
      case 'cancelled':
        parsedStatus = OrderStatus.cancelled;
        break;
    }

    DeliveryPartner? parsedPartner;
    if (json['deliveryPartner'] != null) {
      parsedPartner = DeliveryPartner(
        name: json['deliveryPartner']['name'] ?? '',
        rating: 4.9,
        deliveries: 120,
        avatarUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['deliveryPartner']['name'] ?? '')}&size=200&background=10B981&color=fff',
      );
    }

    DeliveryAddress parsedAddress = const DeliveryAddress(id: '', label: '', street: '', area: '', city: '', pincode: '');
    if (json['addressId'] != null) {
      if (json['addressId'] is Map) {
        parsedAddress = DeliveryAddress.fromJson(json['addressId'] as Map<String, dynamic>);
      } else {
        parsedAddress = DeliveryAddress(id: json['addressId'].toString(), label: 'Default', street: '', area: '', city: '', pincode: '');
      }
    }

    List<CartItem> parsedItems = [];
    if (json['items'] != null) {
      parsedItems = (json['items'] as List).map((i) {
        final itemMap = i as Map<String, dynamic>;
        final menuItem = MenuItem(
          id: itemMap['menuItemId'] ?? '',
          name: itemMap['name'] ?? '',
          description: '',
          price: (itemMap['price'] as num?)?.toDouble() ?? 0.0,
          calories: 0,
          rating: 5.0,
          imageUrl: '',
          category: '',
        );
        return CartItem(menuItem: menuItem, quantity: itemMap['quantity'] ?? 1);
      }).toList();
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      address: parsedAddress,
      paymentMethod: json['paymentMethod'] ?? '',
      status: parsedStatus,
      deliveryPartner: parsedPartner,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      estimatedDelivery: json['estimatedDelivery'] != null ? DateTime.parse(json['estimatedDelivery'] as String) : DateTime.now().add(const Duration(minutes: 35)),
    );
  }
}

class MenuCategory {
  final String name;
  final String emoji;

  const MenuCategory({required this.name, required this.emoji});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '🍽️',
    );
  }
}

class BannerModel {
  final String id;
  final String imagePath;
  final String title;
  final String subtitle;
  final String chipLabel;

  const BannerModel({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.chipLabel,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? json['id'] ?? '',
      imagePath: json['imagePath'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      chipLabel: json['chipLabel'] ?? '',
    );
  }
}
