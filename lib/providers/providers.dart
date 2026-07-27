import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../config/env.dart';
import '../models/models.dart';
import '../services/demo_data.dart';
import '../services/location_service.dart';
import '../services/order_repository.dart';
import '../services/payment_service.dart';
import '../services/restaurant_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  return Supabase.instance.client;
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(client: ref.watch(supabaseClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(client: ref.watch(supabaseClientProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(client: ref.watch(supabaseClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final restaurantProvider = FutureProvider<Restaurant>((ref) {
  return ref.watch(restaurantRepositoryProvider).fetchRestaurant();
});

final categoriesProvider = FutureProvider<List<MenuCategory>>((ref) {
  return ref.watch(restaurantRepositoryProvider).fetchCategories();
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) {
  return ref.watch(restaurantRepositoryProvider).fetchMenuItems();
});

class OrderSession {
  const OrderSession({
    this.orderType,
    this.address,
    this.eta,
    this.guestName = '',
    this.guestEmail = '',
    this.guestPhone = '',
    this.specialInstructions = '',
  });

  final OrderType? orderType;
  final DeliveryAddress? address;
  final EtaEstimate? eta;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String specialInstructions;

  bool get hasOrderType => orderType != null;

  bool get isDeliveryReady =>
      orderType == OrderType.pickup ||
      (orderType == OrderType.delivery &&
          address != null &&
          eta != null &&
          eta!.withinRadius);

  OrderSession copyWith({
    OrderType? orderType,
    DeliveryAddress? address,
    EtaEstimate? eta,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? specialInstructions,
    bool clearAddress = false,
    bool clearEta = false,
  }) {
    return OrderSession(
      orderType: orderType ?? this.orderType,
      address: clearAddress ? null : (address ?? this.address),
      eta: clearEta ? null : (eta ?? this.eta),
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class OrderSessionNotifier extends StateNotifier<OrderSession> {
  OrderSessionNotifier(this._ref) : super(const OrderSession());

  final Ref _ref;

  void selectOrderType(OrderType type) {
    if (type == OrderType.pickup) {
      final restaurant =
          _ref.read(restaurantProvider).valueOrNull ?? DemoData.restaurant;
      state = state.copyWith(
        orderType: type,
        clearAddress: true,
        eta: DistanceService.estimate(
          restaurant: restaurant,
          orderType: type,
        ),
      );
    } else {
      state = state.copyWith(
        orderType: type,
        clearEta: true,
        clearAddress: true,
      );
    }
  }

  Future<void> setDeliveryAddress(DeliveryAddress address) async {
    final restaurant =
        _ref.read(restaurantProvider).valueOrNull ?? DemoData.restaurant;
    final eta = DistanceService.estimate(
      restaurant: restaurant,
      orderType: OrderType.delivery,
      customerLat: address.latitude,
      customerLon: address.longitude,
    );
    state = state.copyWith(
      orderType: OrderType.delivery,
      address: address,
      eta: eta,
    );
  }

  void updateGuest({
    String? name,
    String? email,
    String? phone,
    String? instructions,
  }) {
    state = state.copyWith(
      guestName: name,
      guestEmail: email,
      guestPhone: phone,
      specialInstructions: instructions,
    );
  }

  void reset() => state = const OrderSession();
}

final orderSessionProvider =
    StateNotifierProvider<OrderSessionNotifier, OrderSession>((ref) {
  return OrderSessionNotifier(ref);
});

class CartState {
  const CartState({this.lines = const []});

  final List<CartLine> lines;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  int get subtotalCents =>
      lines.fold(0, (sum, line) => sum + line.lineTotalCents);

  bool get isEmpty => lines.isEmpty;

  CartState copyWith({List<CartLine>? lines}) =>
      CartState(lines: lines ?? this.lines);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(MenuItem item, {int quantity = 1, String notes = ''}) {
    final existing = state.lines.indexWhere((l) => l.item.id == item.id);
    if (existing >= 0) {
      final updated = [...state.lines];
      final current = updated[existing];
      updated[existing] = current.copyWith(
        quantity: current.quantity + quantity,
        notes: notes.isEmpty ? current.notes : notes,
      );
      state = state.copyWith(lines: updated);
    } else {
      state = state.copyWith(
        lines: [
          ...state.lines,
          CartLine(item: item, quantity: quantity, notes: notes),
        ],
      );
    }
  }

  void setQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = state.copyWith(
      lines: state.lines
          .map((l) => l.item.id == itemId ? l.copyWith(quantity: quantity) : l)
          .toList(),
    );
  }

  void increment(String itemId) {
    final line = state.lines.firstWhere((l) => l.item.id == itemId);
    setQuantity(itemId, line.quantity + 1);
  }

  void decrement(String itemId) {
    final line = state.lines.firstWhere((l) => l.item.id == itemId);
    setQuantity(itemId, line.quantity - 1);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.item.id != itemId).toList(),
    );
  }

  void clear() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final cartTotalsProvider = Provider<
    ({
      int subtotal,
      int deliveryFee,
      int tax,
      int total,
    })>((ref) {
  final cart = ref.watch(cartProvider);
  final session = ref.watch(orderSessionProvider);
  final restaurant =
      ref.watch(restaurantProvider).valueOrNull ?? DemoData.restaurant;
  final orderType = session.orderType ?? OrderType.pickup;

  final subtotal = cart.subtotalCents;
  final deliveryFee = DistanceService.deliveryFeeCents(
    restaurant: restaurant,
    orderType: orderType,
    subtotalCents: subtotal,
  );
  final tax = ((subtotal + deliveryFee) *
          (AppConstants.vatRate / (1 + AppConstants.vatRate)))
      .round();
  final total = subtotal + deliveryFee;

  return (
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    tax: tax,
    total: total,
  );
});
