/// App configuration. Prefer --dart-define in production builds.
///
/// Example:
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
///   --dart-define=DEMO_MODE=true
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// When true (or when Supabase is not configured), the app uses local seed data
  /// and simulates payments so you can demo the full UX.
  static const demoModeFlag = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isStripeConfigured => stripePublishableKey.isNotEmpty;

  static bool get useDemoMode => demoModeFlag || !isSupabaseConfigured;

  static String get merchantDisplayName => 'Sabor';

  static String get merchantCountryCode => 'ES';

  static String get currency => 'eur';

  static String get locale => 'es_ES';

  static String get stripeReturnUrl => 'sabor://stripe-redirect';
}
