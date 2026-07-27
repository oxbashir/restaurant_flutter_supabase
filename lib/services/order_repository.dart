import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../config/env.dart';
import '../models/models.dart';

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.orderType,
    required this.items,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.taxCents,
    required this.totalCents,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    this.address,
    this.eta,
    this.specialInstructions,
  });

  final OrderType orderType;
  final List<CartLine> items;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int taxCents;
  final int totalCents;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final DeliveryAddress? address;
  final EtaEstimate? eta;
  final String? specialInstructions;
}

class OrderRepository {
  OrderRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  final _uuid = const Uuid();
  final List<RestaurantOrder> _demoOrders = [];

  String _orderNumber() {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = _uuid.v4().substring(0, 6).toUpperCase();
    return 'SB-$stamp-$suffix';
  }

  Future<RestaurantOrder> createOrder(CreateOrderRequest request) async {
    final orderId = _uuid.v4();
    final orderNumber = _orderNumber();
    final now = DateTime.now();
    final readyAt = request.eta?.readyAt;
    final client = _client;

    final snapshots = request.items
        .map(
          (line) => OrderItemSnapshot(
            menuItemId: line.item.id,
            name: line.item.name,
            unitPriceCents: line.item.priceCents,
            quantity: line.quantity,
            notes: line.notes.isEmpty ? null : line.notes,
          ),
        )
        .toList();

    if (Env.useDemoMode || client == null) {
      final order = RestaurantOrder(
        id: orderId,
        orderNumber: orderNumber,
        orderType: request.orderType,
        status: OrderStatus.pendingPayment,
        subtotalCents: request.subtotalCents,
        deliveryFeeCents: request.deliveryFeeCents,
        taxCents: request.taxCents,
        totalCents: request.totalCents,
        items: snapshots,
        createdAt: now,
        guestName: request.guestName,
        guestEmail: request.guestEmail,
        guestPhone: request.guestPhone,
        deliveryStreet: request.address?.street,
        deliveryCity: request.address?.city,
        deliveryPostalCode: request.address?.postalCode,
        distanceKm: request.eta?.distanceKm,
        estimatedPrepMinutes: request.eta?.prepMinutes,
        estimatedDeliveryMinutes: request.eta?.totalMinutes,
        estimatedReadyAt: readyAt,
        specialInstructions: request.specialInstructions,
      );
      _demoOrders.insert(0, order);
      return order;
    }

    final orderRow = {
      'id': orderId,
      'order_number': orderNumber,
      'restaurant_id': AppConstants.restaurantId,
      'user_id': client.auth.currentUser?.id,
      'guest_name': request.guestName,
      'guest_email': request.guestEmail,
      'guest_phone': request.guestPhone,
      'order_type': request.orderType.dbValue,
      'status': OrderStatus.pendingPayment.dbValue,
      'payment_status': 'pending',
      'subtotal_cents': request.subtotalCents,
      'delivery_fee_cents': request.deliveryFeeCents,
      'tax_cents': request.taxCents,
      'total_cents': request.totalCents,
      'currency': 'eur',
      'delivery_street': request.address?.street,
      'delivery_city': request.address?.city,
      'delivery_postal_code': request.address?.postalCode,
      'delivery_country': request.address?.country ?? 'ES',
      'delivery_latitude': request.address?.latitude,
      'delivery_longitude': request.address?.longitude,
      'delivery_notes': request.address?.notes,
      'distance_km': request.eta?.distanceKm,
      'estimated_prep_minutes': request.eta?.prepMinutes,
      'estimated_delivery_minutes': request.eta?.totalMinutes,
      'estimated_ready_at': readyAt?.toIso8601String(),
      'special_instructions': request.specialInstructions,
    };

    await client.from('orders').insert(orderRow);
    await client.from('order_items').insert(
          snapshots
              .map(
                (s) => {
                  'order_id': orderId,
                  ...s.toJson(),
                },
              )
              .toList(),
        );

    return RestaurantOrder(
      id: orderId,
      orderNumber: orderNumber,
      orderType: request.orderType,
      status: OrderStatus.pendingPayment,
      subtotalCents: request.subtotalCents,
      deliveryFeeCents: request.deliveryFeeCents,
      taxCents: request.taxCents,
      totalCents: request.totalCents,
      items: snapshots,
      createdAt: now,
      guestName: request.guestName,
      guestEmail: request.guestEmail,
      guestPhone: request.guestPhone,
      deliveryStreet: request.address?.street,
      deliveryCity: request.address?.city,
      deliveryPostalCode: request.address?.postalCode,
      distanceKm: request.eta?.distanceKm,
      estimatedPrepMinutes: request.eta?.prepMinutes,
      estimatedDeliveryMinutes: request.eta?.totalMinutes,
      estimatedReadyAt: readyAt,
      specialInstructions: request.specialInstructions,
    );
  }

  Future<RestaurantOrder> markPaid({
    required String orderId,
    required String paymentIntentId,
  }) async {
    final client = _client;
    if (Env.useDemoMode || client == null) {
      final index = _demoOrders.indexWhere((o) => o.id == orderId);
      if (index < 0) {
        throw StateError('Order not found');
      }
      final current = _demoOrders[index];
      final updated = RestaurantOrder(
        id: current.id,
        orderNumber: current.orderNumber,
        orderType: current.orderType,
        status: OrderStatus.confirmed,
        subtotalCents: current.subtotalCents,
        deliveryFeeCents: current.deliveryFeeCents,
        taxCents: current.taxCents,
        totalCents: current.totalCents,
        items: current.items,
        createdAt: current.createdAt,
        guestName: current.guestName,
        guestEmail: current.guestEmail,
        guestPhone: current.guestPhone,
        deliveryStreet: current.deliveryStreet,
        deliveryCity: current.deliveryCity,
        deliveryPostalCode: current.deliveryPostalCode,
        distanceKm: current.distanceKm,
        estimatedPrepMinutes: current.estimatedPrepMinutes,
        estimatedDeliveryMinutes: current.estimatedDeliveryMinutes,
        estimatedReadyAt: current.estimatedReadyAt,
        specialInstructions: current.specialInstructions,
        stripePaymentIntentId: paymentIntentId,
      );
      _demoOrders[index] = updated;
      return updated;
    }

    await client.from('orders').update({
      'status': OrderStatus.confirmed.dbValue,
      'payment_status': 'succeeded',
      'stripe_payment_intent_id': paymentIntentId,
    }).eq('id', orderId);

    return (await fetchOrder(orderId))!;
  }

  Future<RestaurantOrder?> fetchOrder(String orderId) async {
    final client = _client;
    if (Env.useDemoMode || client == null) {
      try {
        return _demoOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return null;
      }
    }

    final data = await client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();

    if (data == null) return null;
    return RestaurantOrder.fromJson(data);
  }

  Future<List<RestaurantOrder>> fetchRecentOrders({int limit = 20}) async {
    final client = _client;
    if (Env.useDemoMode || client == null) {
      return List.unmodifiable(_demoOrders.take(limit));
    }

    final userId = client.auth.currentUser?.id;
    final data = userId == null
        ? await client
            .from('orders')
            .select('*, order_items(*)')
            .order('created_at', ascending: false)
            .limit(limit)
        : await client
            .from('orders')
            .select('*, order_items(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);

    return (data as List)
        .map((e) => RestaurantOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
