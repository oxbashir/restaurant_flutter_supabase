import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../config/env.dart';
import '../models/models.dart';
import 'demo_data.dart';

class RestaurantRepository {
  RestaurantRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  Future<Restaurant> fetchRestaurant() async {
    final client = _client;
    if (Env.useDemoMode || client == null) return DemoData.restaurant;

    final data = await client
        .from('restaurants')
        .select()
        .eq('id', AppConstants.restaurantId)
        .maybeSingle();

    if (data == null) return DemoData.restaurant;
    return Restaurant.fromJson(data);
  }

  Future<List<MenuCategory>> fetchCategories() async {
    final client = _client;
    if (Env.useDemoMode || client == null) return DemoData.categories;

    final data = await client
        .from('categories')
        .select()
        .eq('restaurant_id', AppConstants.restaurantId)
        .eq('is_active', true)
        .order('sort_order');

    return (data as List)
        .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MenuItem>> fetchMenuItems() async {
    final client = _client;
    if (Env.useDemoMode || client == null) return DemoData.items;

    final data = await client
        .from('menu_items')
        .select()
        .eq('restaurant_id', AppConstants.restaurantId)
        .eq('is_available', true)
        .order('sort_order');

    return (data as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
