import 'package:equatable/equatable.dart';

enum OrderType { delivery, pickup }

extension OrderTypeX on OrderType {
  String get label => this == OrderType.delivery ? 'Delivery' : 'Pickup';
  String get labelEs => this == OrderType.delivery ? 'A domicilio' : 'Recoger';
  String get dbValue => name;
  static OrderType fromString(String value) =>
      value == 'pickup' ? OrderType.pickup : OrderType.delivery;
}

class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.prepTimeMinutes,
    required this.deliveryFeeCents,
    required this.freeDeliveryOverCents,
    required this.minOrderCents,
    required this.avgSpeedKmh,
    required this.deliveryRadiusKm,
    required this.isOpen,
  });

  final String id;
  final String name;
  final String tagline;
  final String address;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String phone;
  final int prepTimeMinutes;
  final int deliveryFeeCents;
  final int freeDeliveryOverCents;
  final int minOrderCents;
  final double avgSpeedKmh;
  final double deliveryRadiusKm;
  final bool isOpen;

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: (json['tagline'] as String?) ?? '',
        address: json['address'] as String,
        city: json['city'] as String? ?? 'Madrid',
        postalCode: json['postal_code'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String? ?? '',
        prepTimeMinutes: json['prep_time_minutes'] as int? ?? 20,
        deliveryFeeCents: json['delivery_fee_cents'] as int? ?? 250,
        freeDeliveryOverCents:
            json['free_delivery_over_cents'] as int? ?? 2500,
        minOrderCents: json['min_order_cents'] as int? ?? 800,
        avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 25,
        deliveryRadiusKm:
            (json['delivery_radius_km'] as num?)?.toDouble() ?? 12,
        isOpen: json['is_open'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name];
}

class MenuCategory extends Equatable {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.sortOrder,
    this.description,
  });

  final String id;
  final String name;
  final String nameEs;
  final String? description;
  final int sortOrder;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEs: (json['name_es'] as String?) ?? json['name'] as String,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id];
}

class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.nameEs,
    required this.description,
    required this.descriptionEs,
    required this.priceCents,
    required this.imageUrl,
    required this.isFeatured,
    required this.tags,
    required this.allergens,
    this.calories,
    this.prepMinutes,
  });

  final String id;
  final String categoryId;
  final String name;
  final String nameEs;
  final String description;
  final String descriptionEs;
  final int priceCents;
  final String imageUrl;
  final bool isFeatured;
  final List<String> tags;
  final List<String> allergens;
  final int? calories;
  final int? prepMinutes;

  double get priceEuros => priceCents / 100.0;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        nameEs: (json['name_es'] as String?) ?? json['name'] as String,
        description: (json['description'] as String?) ?? '',
        descriptionEs:
            (json['description_es'] as String?) ?? (json['description'] as String?) ?? '',
        priceCents: json['price_cents'] as int,
        imageUrl: (json['image_url'] as String?) ?? '',
        isFeatured: json['is_featured'] as bool? ?? false,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        allergens:
            (json['allergens'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        calories: json['calories'] as int?,
        prepMinutes: json['prep_minutes'] as int?,
      );

  @override
  List<Object?> get props => [id];
}

class DeliveryAddress extends Equatable {
  const DeliveryAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    this.country = 'ES',
    this.latitude,
    this.longitude,
    this.notes,
    this.label = 'Home',
  });

  final String street;
  final String city;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String label;

  String get formatted => '$street, $postalCode $city';

  bool get hasCoordinates => latitude != null && longitude != null;

  DeliveryAddress copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? notes,
    String? label,
  }) {
    return DeliveryAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'label': label,
      };

  @override
  List<Object?> get props =>
      [street, city, postalCode, country, latitude, longitude];
}

class CartLine extends Equatable {
  const CartLine({
    required this.item,
    required this.quantity,
    this.notes = '',
  });

  final MenuItem item;
  final int quantity;
  final String notes;

  int get lineTotalCents => item.priceCents * quantity;

  CartLine copyWith({MenuItem? item, int? quantity, String? notes}) => CartLine(
        item: item ?? this.item,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [item.id, quantity, notes];
}

class EtaEstimate extends Equatable {
  const EtaEstimate({
    required this.distanceKm,
    required this.prepMinutes,
    required this.travelMinutes,
    required this.totalMinutes,
    required this.withinRadius,
  });

  final double distanceKm;
  final int prepMinutes;
  final int travelMinutes;
  final int totalMinutes;
  final bool withinRadius;

  DateTime get readyAt => DateTime.now().add(Duration(minutes: totalMinutes));

  @override
  List<Object?> get props =>
      [distanceKm, prepMinutes, travelMinutes, totalMinutes, withinRadius];
}

enum OrderStatus {
  pendingPayment,
  paid,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Pending payment';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'On the way';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromDb(String value) {
    switch (value) {
      case 'pending_payment':
        return OrderStatus.pendingPayment;
      case 'paid':
        return OrderStatus.paid;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingPayment;
    }
  }

  String get dbValue {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'pending_payment';
      case OrderStatus.paid:
        return 'paid';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

class OrderItemSnapshot extends Equatable {
  const OrderItemSnapshot({
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
    this.menuItemId,
    this.notes,
  });

  final String? menuItemId;
  final String name;
  final int unitPriceCents;
  final int quantity;
  final String? notes;

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderItemSnapshot(
        menuItemId: json['menu_item_id'] as String?,
        name: json['name'] as String,
        unitPriceCents: json['unit_price_cents'] as int,
        quantity: json['quantity'] as int,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'unit_price_cents': unitPriceCents,
        'quantity': quantity,
        'notes': notes,
      };

  @override
  List<Object?> get props => [menuItemId, name, unitPriceCents, quantity];
}

class RestaurantOrder extends Equatable {
  const RestaurantOrder({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.taxCents,
    required this.totalCents,
    required this.items,
    required this.createdAt,
    this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.deliveryStreet,
    this.deliveryCity,
    this.deliveryPostalCode,
    this.distanceKm,
    this.estimatedPrepMinutes,
    this.estimatedDeliveryMinutes,
    this.estimatedReadyAt,
    this.specialInstructions,
    this.stripePaymentIntentId,
  });

  final String id;
  final String orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int taxCents;
  final int totalCents;
  final List<OrderItemSnapshot> items;
  final DateTime createdAt;
  final String? guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String? deliveryStreet;
  final String? deliveryCity;
  final String? deliveryPostalCode;
  final double? distanceKm;
  final int? estimatedPrepMinutes;
  final int? estimatedDeliveryMinutes;
  final DateTime? estimatedReadyAt;
  final String? specialInstructions;
  final String? stripePaymentIntentId;

  factory RestaurantOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List? ?? const [];
    return RestaurantOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      orderType: OrderTypeX.fromString(json['order_type'] as String),
      status: OrderStatusX.fromDb(json['status'] as String),
      subtotalCents: json['subtotal_cents'] as int,
      deliveryFeeCents: json['delivery_fee_cents'] as int? ?? 0,
      taxCents: json['tax_cents'] as int? ?? 0,
      totalCents: json['total_cents'] as int,
      items: rawItems
          .map((e) => OrderItemSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      guestName: json['guest_name'] as String?,
      guestEmail: json['guest_email'] as String?,
      guestPhone: json['guest_phone'] as String?,
      deliveryStreet: json['delivery_street'] as String?,
      deliveryCity: json['delivery_city'] as String?,
      deliveryPostalCode: json['delivery_postal_code'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedPrepMinutes: json['estimated_prep_minutes'] as int?,
      estimatedDeliveryMinutes: json['estimated_delivery_minutes'] as int?,
      estimatedReadyAt: json['estimated_ready_at'] == null
          ? null
          : DateTime.parse(json['estimated_ready_at'] as String),
      specialInstructions: json['special_instructions'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, orderNumber, status];
}

class PaymentIntentResult {
  const PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    this.ephemeralKey,
    this.customerId,
  });

  final String clientSecret;
  final String paymentIntentId;
  final String? ephemeralKey;
  final String? customerId;
}
