# Sabor — Restaurant Ordering (Flutter + Supabase)

Modern light Mediterranean ordering app for **delivery** and **pickup**, with cart, distance-based ETA and Stripe payments 

## Features

- Order type selection on home (Delivery / Pickup)
- Delivery address capture + location permission
- ETA from restaurant distance (Haversine + prep time)
- Menu with categories, featured items, allergens
- Cart with min order / free delivery rules
- Checkout + Stripe Payment Sheet (cards, Apple Pay, Google Pay) for **ES / EUR**
- Orders history + confirmation
- **Demo mode** works out of the box without backend keys

## Quick start (demo)

```bash
flutter pub get
flutter run
```

Demo mode is on by default (`DEMO_MODE=true`). Payments are simulated; menu data is local seed data mirroring the Supabase migration.

## Production setup

### 1. Supabase

1. Create a Supabase project
2. Run `supabase/migrations/001_schema.sql` in the SQL editor
3. Deploy the payment function:

```bash
supabase functions deploy create-payment-intent
supabase secrets set STRIPE_SECRET_KEY=sk_live_or_test_xxx
```

### 2. Stripe (Spain)

1. Create a Stripe account with country **Spain**, currency **EUR**
2. Enable Payment Methods: Cards, Apple Pay, Google Pay (and Bizum if available on your Stripe account)
3. Copy the publishable key into the Flutter run command

### 3. Run with real backends

```bash
flutter run \
  --dart-define=DEMO_MODE=false \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_or_live_xxx
```

### Android / iOS notes

- Android `MainActivity` extends `FlutterFragmentActivity` (required by Stripe)
- Location + Internet permissions configured
- Deep link scheme `sabor://` for Stripe redirects
- iOS location usage strings included in `Info.plist`

## UX flow

1. **Home** → choose Delivery or Pickup  
2. **Delivery** → enter address (or use GPS) → ETA from distance  
3. **Menu** → browse / add items  
4. **Cart** → adjust quantities, see fees & IVA  
5. **Checkout** → contact details → pay in EUR  
6. **Confirmation** → order number + ready time  

## Project structure

```
lib/
  config/          # Env + constants
  theme/           # Light colourful theme
  models/          # Domain models
  services/        # Supabase, Stripe, geocoding, demo data
  providers/       # Riverpod state (cart, session)
  screens/         # UI flows
  widgets/         # Shared UI
supabase/
  migrations/      # Schema + seed menu
  functions/       # Stripe PaymentIntent edge function
```

## Restaurant defaults

Seeded restaurant is in Madrid (Calle de Serrano 45). Adjust lat/lng, fees, and radius in the `restaurants` table.
