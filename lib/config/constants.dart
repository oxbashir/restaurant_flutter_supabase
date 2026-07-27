class AppConstants {
  static const appName = 'Sabor';
  static const tagline = 'Cocina mediterránea fresca';

  /// Default restaurant UUID — matches seed data.
  static const restaurantId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  static const defaultPrepMinutes = 20;
  static const defaultAvgSpeedKmh = 25.0;
  static const defaultDeliveryFeeCents = 250;
  static const freeDeliveryOverCents = 2500;
  static const minOrderCents = 800;
  static const deliveryRadiusKm = 12.0;

  /// Spanish IVA estimate shown on receipts (included in menu prices for B2C).
  static const vatRate = 0.10;
}
