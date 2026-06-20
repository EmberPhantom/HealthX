import 'package:equatable/equatable.dart';

class UserSubscription extends Equatable {
  final String id;
  final String planId;
  final String planName;
  final String status;
  final String price;
  final DateTime startDate;
  final DateTime endDate;
  final String billingPeriod;

  const UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.billingPeriod,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['_id'] ?? json['id'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? 'active',
      price: json['price']?.toString() ?? '0',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      billingPeriod: json['billingPeriod'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'planName': planName,
    'status': status,
    'price': price,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'billingPeriod': billingPeriod,
  };

  @override
  List<Object?> get props => [id, planId, planName, status, price, startDate, endDate, billingPeriod];
}

class SubscriptionPlan extends Equatable {
  final String planId;
  final String planName;
  final double price;
  final List<String> features;
  final bool isBestseller;

  const SubscriptionPlan({
    required this.planId,
    required this.planName,
    required this.price,
    required this.features,
    this.isBestseller = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(json['features'] ?? []),
      isBestseller: json['isBestseller'] ?? false,
    );
  }

  @override
  List<Object?> get props => [planId, planName, price, features, isBestseller];
}

