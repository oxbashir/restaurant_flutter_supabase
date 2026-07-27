import 'dart:math' as math;

import '../config/constants.dart';
import '../models/models.dart';

class Money {
  static String formatCents(int cents, {String currency = 'EUR'}) {
    final value = cents / 100.0;
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$fixed €';
  }
}

class DistanceService {
  /// Haversine distance in kilometres.
  static double haversineKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  static EtaEstimate estimate({
    required Restaurant restaurant,
    required OrderType orderType,
    double? customerLat,
    double? customerLon,
  }) {
    final prep = restaurant.prepTimeMinutes;

    if (orderType == OrderType.pickup ||
        customerLat == null ||
        customerLon == null) {
      return EtaEstimate(
        distanceKm: 0,
        prepMinutes: prep,
        travelMinutes: 0,
        totalMinutes: prep,
        withinRadius: true,
      );
    }

    final distance = haversineKm(
      lat1: restaurant.latitude,
      lon1: restaurant.longitude,
      lat2: customerLat,
      lon2: customerLon,
    );

    final travel = (distance / restaurant.avgSpeedKmh * 60).ceil().clamp(5, 90);
    final buffer = 5;
    final within = distance <= restaurant.deliveryRadiusKm;

    return EtaEstimate(
      distanceKm: double.parse(distance.toStringAsFixed(2)),
      prepMinutes: prep,
      travelMinutes: travel,
      totalMinutes: prep + travel + buffer,
      withinRadius: within,
    );
  }

  static int deliveryFeeCents({
    required Restaurant restaurant,
    required OrderType orderType,
    required int subtotalCents,
  }) {
    if (orderType == OrderType.pickup) return 0;
    if (subtotalCents >= restaurant.freeDeliveryOverCents) return 0;
    return restaurant.deliveryFeeCents;
  }
}

class DemoData {
  static Restaurant get restaurant => const Restaurant(
        id: AppConstants.restaurantId,
        name: AppConstants.appName,
        tagline: AppConstants.tagline,
        address: 'Calle de Serrano 45',
        city: 'Madrid',
        postalCode: '28001',
        latitude: 40.4275,
        longitude: -3.6870,
        phone: '+34 910 000 000',
        prepTimeMinutes: AppConstants.defaultPrepMinutes,
        deliveryFeeCents: AppConstants.defaultDeliveryFeeCents,
        freeDeliveryOverCents: AppConstants.freeDeliveryOverCents,
        minOrderCents: AppConstants.minOrderCents,
        avgSpeedKmh: AppConstants.defaultAvgSpeedKmh,
        deliveryRadiusKm: AppConstants.deliveryRadiusKm,
        isOpen: true,
      );

  static List<MenuCategory> get categories => const [
        MenuCategory(
          id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Starters',
          nameEs: 'Entrantes',
          description: 'Light bites to begin',
          sortOrder: 1,
        ),
        MenuCategory(
          id: 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Mains',
          nameEs: 'Principales',
          description: 'Hearty Mediterranean plates',
          sortOrder: 2,
        ),
        MenuCategory(
          id: 'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Bowls & Salads',
          nameEs: 'Bowls y ensaladas',
          description: 'Fresh and vibrant',
          sortOrder: 3,
        ),
        MenuCategory(
          id: 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Drinks',
          nameEs: 'Bebidas',
          description: 'Refreshments',
          sortOrder: 4,
        ),
        MenuCategory(
          id: 'b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Desserts',
          nameEs: 'Postres',
          description: 'Sweet endings',
          sortOrder: 5,
        ),
      ];

  static List<MenuItem> get items => const [
        MenuItem(
          id: 'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Patatas Bravas',
          nameEs: 'Patatas Bravas',
          description: 'Crispy potatoes with smoky paprika aioli',
          descriptionEs: 'Patatas crujientes con alioli de pimentón',
          priceCents: 650,
          imageUrl:
              'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?w=800',
          isFeatured: true,
          tags: ['spicy', 'vegetarian'],
          allergens: ['egg'],
          calories: 320,
          prepMinutes: 12,
        ),
        MenuItem(
          id: 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Gambas al Ajillo',
          nameEs: 'Gambas al Ajillo',
          description: 'Garlic prawns in olive oil and chilli',
          descriptionEs: 'Gambas al ajillo con guindilla',
          priceCents: 1150,
          imageUrl:
              'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800',
          isFeatured: true,
          tags: ['seafood'],
          allergens: ['crustaceans'],
          calories: 280,
          prepMinutes: 10,
        ),
        MenuItem(
          id: 'c3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Pan con Tomate',
          nameEs: 'Pan con Tomate',
          description: 'Toasted sourdough with ripe tomato and olive oil',
          descriptionEs: 'Pan tostado con tomate y aceite de oliva',
          priceCents: 450,
          imageUrl:
              'https://images.unsplash.com/photo-1506280754576-f6fa8a873550?w=800',
          isFeatured: false,
          tags: ['vegan'],
          allergens: ['gluten'],
          calories: 210,
          prepMinutes: 5,
        ),
        MenuItem(
          id: 'c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Paella de Marisco',
          nameEs: 'Paella de Marisco',
          description: 'Saffron rice with mussels, prawns and squid',
          descriptionEs: 'Arroz con azafrán, mejillones, gambas y calamar',
          priceCents: 1850,
          imageUrl:
              'https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=800',
          isFeatured: true,
          tags: ['seafood', 'signature'],
          allergens: ['molluscs', 'crustaceans'],
          calories: 620,
          prepMinutes: 25,
        ),
        MenuItem(
          id: 'c5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Pollo al Ajillo',
          nameEs: 'Pollo al Ajillo',
          description: 'Slow-cooked garlic chicken with roasted peppers',
          descriptionEs: 'Pollo al ajillo con pimientos asados',
          priceCents: 1450,
          imageUrl:
              'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800',
          isFeatured: false,
          tags: ['popular'],
          allergens: [],
          calories: 540,
          prepMinutes: 18,
        ),
        MenuItem(
          id: 'c6eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Bacalao a la Vizcaína',
          nameEs: 'Bacalao a la Vizcaína',
          description: 'Cod in Basque pepper sauce',
          descriptionEs: 'Bacalao en salsa vizcaína',
          priceCents: 1680,
          imageUrl:
              'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800',
          isFeatured: true,
          tags: ['fish'],
          allergens: ['fish'],
          calories: 480,
          prepMinutes: 20,
        ),
        MenuItem(
          id: 'c7eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Ensalada Mediterránea',
          nameEs: 'Ensalada Mediterránea',
          description: 'Tomato, cucumber, olives, feta and oregano',
          descriptionEs: 'Tomate, pepino, aceitunas, feta y orégano',
          priceCents: 980,
          imageUrl:
              'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
          isFeatured: false,
          tags: ['vegetarian', 'healthy'],
          allergens: ['dairy'],
          calories: 340,
          prepMinutes: 8,
        ),
        MenuItem(
          id: 'c8eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Bowl de Quinoa',
          nameEs: 'Bowl de Quinoa',
          description: 'Quinoa, roasted veg, chickpeas and tahini',
          descriptionEs: 'Quinoa, verduras asadas, garbanzos y tahini',
          priceCents: 1120,
          imageUrl:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
          isFeatured: true,
          tags: ['vegan', 'healthy'],
          allergens: ['sesame'],
          calories: 410,
          prepMinutes: 10,
        ),
        MenuItem(
          id: 'c9eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Agua Mineral',
          nameEs: 'Agua Mineral',
          description: 'Still or sparkling 50cl',
          descriptionEs: 'Con o sin gas 50cl',
          priceCents: 250,
          imageUrl:
              'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800',
          isFeatured: false,
          tags: ['drinks'],
          allergens: [],
          calories: 0,
          prepMinutes: 1,
        ),
        MenuItem(
          id: 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Sangría de Casa',
          nameEs: 'Sangría de Casa',
          description: 'House red sangria with seasonal fruit',
          descriptionEs: 'Sangría tinta con fruta de temporada',
          priceCents: 650,
          imageUrl:
              'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800',
          isFeatured: true,
          tags: ['drinks', 'alcohol'],
          allergens: ['sulphites'],
          calories: 180,
          prepMinutes: 3,
        ),
        MenuItem(
          id: 'caeebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Café con Leche',
          nameEs: 'Café con Leche',
          description: 'Spanish-style coffee with steamed milk',
          descriptionEs: 'Café con leche cremoso',
          priceCents: 280,
          imageUrl:
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800',
          isFeatured: false,
          tags: ['drinks', 'hot'],
          allergens: ['dairy'],
          calories: 90,
          prepMinutes: 4,
        ),
        MenuItem(
          id: 'cbeebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Crema Catalana',
          nameEs: 'Crema Catalana',
          description: 'Burnt-sugar custard with citrus zest',
          descriptionEs: 'Crema quemada con cítricos',
          priceCents: 620,
          imageUrl:
              'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
          isFeatured: true,
          tags: ['dessert'],
          allergens: ['dairy', 'egg'],
          calories: 310,
          prepMinutes: 5,
        ),
        MenuItem(
          id: 'cceebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          categoryId: 'b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Churros con Chocolate',
          nameEs: 'Churros con Chocolate',
          description: 'Warm churros with thick hot chocolate',
          descriptionEs: 'Churros calientes con chocolate espeso',
          priceCents: 690,
          imageUrl:
              'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800',
          isFeatured: true,
          tags: ['dessert', 'popular'],
          allergens: ['gluten', 'dairy'],
          calories: 450,
          prepMinutes: 8,
        ),
      ];
}
