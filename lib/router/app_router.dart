import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/address/address_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/item_detail/item_detail_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/orders/order_confirmation_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/splash/splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/address',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final items = ref.read(menuItemsProvider).valueOrNull ?? const [];
          MenuItem? item;
          for (final i in items) {
            if (i.id == id) {
              item = i;
              break;
            }
          }
          if (item == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Item not found')),
            );
          }
          return ItemDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderConfirmationScreen(orderId: id);
        },
      ),
    ],
  );
});
