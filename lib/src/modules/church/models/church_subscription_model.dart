import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionAddon {
  const SubscriptionAddon({
    required this.type,
    required this.quantity,
    required this.price,
  });

  final String type;
  final int quantity;
  final double price;

  factory SubscriptionAddon.fromJson(Map<String, dynamic> json) {
    return SubscriptionAddon(
      type: json['type']?.toString() ?? '',
      quantity: (json['quantity'] as int?) ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'quantity': quantity,
    'price': price,
  };
}

class ChurchSubscriptionModel {
  const ChurchSubscriptionModel({
    required this.churchId,
    required this.tier,
    required this.userLimit,
    required this.billingStatus,
    required this.billingCycle,
    this.addons = const [],
    this.stripeCustomerId,
    this.trialEndsAt,
    this.nextBillingDate,
  });

  final String churchId;
  final String tier;
  final int userLimit;
  final String billingStatus;
  final String billingCycle;
  final List<SubscriptionAddon> addons;
  final String? stripeCustomerId;
  final DateTime? trialEndsAt;
  final DateTime? nextBillingDate;

  bool get isActive => billingStatus == 'active';
  bool get isTrial => billingStatus == 'trial';
  bool get isPastDue => billingStatus == 'past_due';

  static int getDefaultUserLimit(String tier) {
    switch (tier) {
      case 'free':
        return 30;
      case 'basic':
        return 100;
      case 'pro':
        return 300;
      case 'max':
        return 999999;
      default:
        return 30;
    }
  }

  factory ChurchSubscriptionModel.defaultFree(String churchId) {
    return ChurchSubscriptionModel(
      churchId: churchId,
      tier: 'free',
      userLimit: 30,
      billingStatus: 'active',
      billingCycle: 'free',
    );
  }

  factory ChurchSubscriptionModel.fromJson(Map<String, dynamic> json, String churchId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return ChurchSubscriptionModel(
      churchId: churchId,
      tier: json['tier']?.toString() ?? 'free',
      userLimit: (json['userLimit'] as int?) ?? 30,
      billingStatus: json['billingStatus']?.toString() ?? 'active',
      billingCycle: json['billingCycle']?.toString() ?? 'free',
      addons: (json['addons'] as List<dynamic>?)
              ?.map((e) => SubscriptionAddon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stripeCustomerId: json['stripeCustomerId']?.toString(),
      trialEndsAt: parseDate(json['trialEndsAt']),
      nextBillingDate: parseDate(json['nextBillingDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'userLimit': userLimit,
    'billingStatus': billingStatus,
    'billingCycle': billingCycle,
    if (addons.isNotEmpty) 'addons': addons.map((a) => a.toJson()).toList(),
    if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
    if (trialEndsAt != null) 'trialEndsAt': Timestamp.fromDate(trialEndsAt!),
    if (nextBillingDate != null) 'nextBillingDate': Timestamp.fromDate(nextBillingDate!),
  };
}
