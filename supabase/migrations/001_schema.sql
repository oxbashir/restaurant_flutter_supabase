-- Sabor Restaurant Ordering System
-- Run in Supabase SQL Editor or via supabase db push

create extension if not exists "pgcrypto";

-- Restaurant settings
create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tagline text,
  address text not null,
  city text not null default 'Madrid',
  postal_code text,
  country text not null default 'ES',
  latitude double precision not null,
  longitude double precision not null,
  phone text,
  email text,
  currency text not null default 'eur',
  prep_time_minutes int not null default 20,
  delivery_fee_cents int not null default 250,
  free_delivery_over_cents int not null default 2500,
  min_order_cents int not null default 800,
  avg_speed_kmh double precision not null default 25,
  delivery_radius_km double precision not null default 12,
  is_open boolean not null default true,
  open_time time not null default '11:00',
  close_time time not null default '23:00',
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  name_es text,
  description text,
  sort_order int not null default 0,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  name text not null,
  name_es text,
  description text,
  description_es text,
  price_cents int not null check (price_cents >= 0),
  image_url text,
  is_available boolean not null default true,
  is_featured boolean not null default false,
  tags text[] default '{}',
  allergens text[] default '{}',
  calories int,
  prep_minutes int,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  label text default 'Home',
  street text not null,
  city text not null,
  postal_code text not null,
  country text not null default 'ES',
  latitude double precision,
  longitude double precision,
  notes text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create type public.order_type as enum ('delivery', 'pickup');
create type public.order_status as enum (
  'pending_payment',
  'paid',
  'confirmed',
  'preparing',
  'ready',
  'out_for_delivery',
  'completed',
  'cancelled'
);
create type public.payment_status as enum (
  'pending',
  'requires_action',
  'succeeded',
  'failed',
  'refunded'
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  restaurant_id uuid not null references public.restaurants(id),
  user_id uuid references auth.users(id) on delete set null,
  guest_email text,
  guest_name text,
  guest_phone text,
  order_type public.order_type not null,
  status public.order_status not null default 'pending_payment',
  payment_status public.payment_status not null default 'pending',
  stripe_payment_intent_id text,
  subtotal_cents int not null,
  delivery_fee_cents int not null default 0,
  tax_cents int not null default 0,
  total_cents int not null,
  currency text not null default 'eur',
  delivery_street text,
  delivery_city text,
  delivery_postal_code text,
  delivery_country text default 'ES',
  delivery_latitude double precision,
  delivery_longitude double precision,
  delivery_notes text,
  distance_km double precision,
  estimated_prep_minutes int,
  estimated_delivery_minutes int,
  estimated_ready_at timestamptz,
  special_instructions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  name text not null,
  unit_price_cents int not null,
  quantity int not null check (quantity > 0),
  notes text,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_menu_items_category on public.menu_items(category_id);
create index if not exists idx_menu_items_restaurant on public.menu_items(restaurant_id);
create index if not exists idx_orders_user on public.orders(user_id);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_categories_restaurant on public.categories(restaurant_id);

-- Updated_at trigger
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists orders_updated_at on public.orders;
create trigger orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

-- Order number generator
create or replace function public.generate_order_number()
returns text as $$
declare
  candidate text;
begin
  loop
    candidate := 'SB-' || to_char(now(), 'YYMMDD') || '-' || upper(substr(encode(gen_random_bytes(3), 'hex'), 1, 6));
    exit when not exists (select 1 from public.orders where order_number = candidate);
  end loop;
  return candidate;
end;
$$ language plpgsql;

-- Auth profile bootstrap
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS
alter table public.restaurants enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.profiles enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "Public read restaurants"
  on public.restaurants for select using (true);

create policy "Public read categories"
  on public.categories for select using (is_active = true);

create policy "Public read menu items"
  on public.menu_items for select using (is_available = true);

create policy "Users read own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users update own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Users manage own addresses"
  on public.customer_addresses for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Anyone can create orders"
  on public.orders for insert with check (true);

create policy "Users read own orders"
  on public.orders for select using (
    auth.uid() = user_id or user_id is null
  );

create policy "Users update own pending orders"
  on public.orders for update using (
    auth.uid() = user_id or user_id is null
  );

create policy "Anyone can create order items"
  on public.order_items for insert with check (true);

create policy "Read order items of visible orders"
  on public.order_items for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (o.user_id = auth.uid() or o.user_id is null)
    )
  );

-- Seed restaurant (Madrid)
insert into public.restaurants (
  id, name, tagline, address, city, postal_code, country,
  latitude, longitude, phone, email, prep_time_minutes,
  delivery_fee_cents, free_delivery_over_cents, min_order_cents
) values (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'Sabor',
  'Cocina mediterránea fresca',
  'Calle de Serrano 45',
  'Madrid',
  '28001',
  'ES',
  40.4275,
  -3.6870,
  '+34 910 000 000',
  'hola@sabor.app',
  20,
  250,
  2500,
  800
) on conflict (id) do nothing;

insert into public.categories (id, restaurant_id, name, name_es, description, sort_order) values
  ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Starters', 'Entrantes', 'Light bites to begin', 1),
  ('b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Mains', 'Principales', 'Hearty Mediterranean plates', 2),
  ('b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Bowls & Salads', 'Bowls y ensaladas', 'Fresh and vibrant', 3),
  ('b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Drinks', 'Bebidas', 'Refreshments', 4),
  ('b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Desserts', 'Postres', 'Sweet endings', 5)
on conflict (id) do nothing;

insert into public.menu_items (
  id, restaurant_id, category_id, name, name_es, description, description_es,
  price_cents, image_url, is_featured, tags, allergens, calories, prep_minutes, sort_order
) values
  ('c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Patatas Bravas', 'Patatas Bravas', 'Crispy potatoes with smoky paprika aioli', 'Patatas crujientes con alioli de pimentón',
   650, 'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?w=800', true, array['spicy','vegetarian'], array['egg'], 320, 12, 1),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Gambas al Ajillo', 'Gambas al Ajillo', 'Garlic prawns in olive oil and chilli', 'Gambas al ajillo con guindilla',
   1150, 'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800', true, array['seafood'], array['crustaceans'], 280, 10, 2),
  ('c3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Pan con Tomate', 'Pan con Tomate', 'Toasted sourdough with ripe tomato and olive oil', 'Pan tostado con tomate y aceite de oliva',
   450, 'https://images.unsplash.com/photo-1506280754576-f6fa8a873550?w=800', false, array['vegan'], array['gluten'], 210, 5, 3),
  ('c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Paella de Marisco', 'Paella de Marisco', 'Saffron rice with mussels, prawns and squid', 'Arroz con azafrán, mejillones, gambas y calamar',
   1850, 'https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=800', true, array['seafood','signature'], array['molluscs','crustaceans'], 620, 25, 1),
  ('c5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Pollo al Ajillo', 'Pollo al Ajillo', 'Slow-cooked garlic chicken with roasted peppers', 'Pollo al ajillo con pimientos asados',
   1450, 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800', false, array['popular'], array[], 540, 18, 2),
  ('c6eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Bacalao a la Vizcaína', 'Bacalao a la Vizcaína', 'Cod in Basque pepper sauce', 'Bacalao en salsa vizcaína',
   1680, 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800', true, array['fish'], array['fish'], 480, 20, 3),
  ('c7eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Ensalada Mediterránea', 'Ensalada Mediterránea', 'Tomato, cucumber, olives, feta and oregano', 'Tomate, pepino, aceitunas, feta y orégano',
   980, 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800', false, array['vegetarian','healthy'], array['dairy'], 340, 8, 1),
  ('c8eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Bowl de Quinoa', 'Bowl de Quinoa', 'Quinoa, roasted veg, chickpeas and tahini', 'Quinoa, verduras asadas, garbanzos y tahini',
   1120, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800', true, array['vegan','healthy'], array['sesame'], 410, 10, 2),
  ('c9eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Agua Mineral', 'Agua Mineral', 'Still or sparkling 50cl', 'Con o sin gas 50cl',
   250, 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800', false, array['drinks'], array[], 0, 1, 1),
  ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Sangría de Casa', 'Sangría de Casa', 'House red sangria with seasonal fruit', 'Sangría tinta con fruta de temporada',
   650, 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800', true, array['drinks','alcohol'], array['sulphites'], 180, 3, 2),
  ('caeebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b4eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Café con Leche', 'Café con Leche', 'Spanish-style coffee with steamed milk', 'Café con leche cremoso',
   280, 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800', false, array['drinks','hot'], array['dairy'], 90, 4, 3),
  ('cbeebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Crema Catalana', 'Crema Catalana', 'Burnt-sugar custard with citrus zest', 'Crema quemada con cítricos',
   620, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800', true, array['dessert'], array['dairy','egg'], 310, 5, 1),
  ('cceebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b5eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
   'Churros con Chocolate', 'Churros con Chocolate', 'Warm churros with thick hot chocolate', 'Churros calientes con chocolate espeso',
   690, 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800', true, array['dessert','popular'], array['gluten','dairy'], 450, 8, 2)
on conflict (id) do nothing;
