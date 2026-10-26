-- Run once in Supabase SQL Editor. For a NEW Supabase project.
create extension if not exists pgcrypto;
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null, category text not null default 'Peripherals',
  description text not null default '', image_url text not null default '',
  price numeric(12,2) not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  external_id text unique not null,
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'PENDING' check (status in ('PENDING','PAID','FAILED')),
  invoice_url text,
  created_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0)
);
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
create policy "public active products" on public.products for select to anon, authenticated using (is_active);
create policy "read own orders" on public.orders for select to authenticated using (user_id = (select auth.uid()));
create policy "read own order items" on public.order_items for select to authenticated using (
  exists (select 1 from public.orders where orders.id = order_id and (orders.user_id = (select auth.uid())))
);
-- Orders are created and updated by Edge Functions using service role ONLY.
-- Never add public INSERT/UPDATE policies for paid orders.

