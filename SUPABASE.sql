-- KATKIT — schéma initial de gestion boutique
-- À exécuter dans Supabase > SQL Editor une fois.
create table if not exists public.katkit_products (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 name text not null,
 category text,
 price numeric(14,2) not null default 0 check(price >= 0),
 stock integer not null default 0 check(stock >= 0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.katkit_sales (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 product_id uuid,
 product_name text not null,
 customer_name text,
 quantity integer not null check(quantity > 0),
 unit_price numeric(14,2) not null check(unit_price >= 0),
 total numeric(14,2) not null check(total >= 0),
 created_at timestamptz not null default now()
);
create index if not exists katkit_products_user_id_idx on public.katkit_products(user_id);
create index if not exists katkit_sales_user_created_idx on public.katkit_sales(user_id,created_at desc);
alter table public.katkit_products enable row level security;
alter table public.katkit_sales enable row level security;
drop policy if exists "KATKIT users manage own products" on public.katkit_products;
create policy "KATKIT users manage own products" on public.katkit_products for all to authenticated
using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "KATKIT users manage own sales" on public.katkit_sales;
create policy "KATKIT users manage own sales" on public.katkit_sales for all to authenticated
using(auth.uid()=user_id) with check(auth.uid()=user_id);
grant select,insert,update,delete on public.katkit_products to authenticated;
grant select,insert,update,delete on public.katkit_sales to authenticated;

-- Répertoire des clients KATKIT
create table if not exists public.katkit_customers (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 name text not null,
 phone text,
 address text,
 notes text,
 created_at timestamptz not null default now()
);

-- Dettes et remboursements clients
create table if not exists public.katkit_debts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 customer_id uuid not null references public.katkit_customers(id) on delete cascade,
 description text not null,
 amount numeric(14,2) not null check(amount > 0),
 paid numeric(14,2) not null default 0 check(paid >= 0 and paid <= amount),
 due_date date,
 created_at timestamptz not null default now()
);
create index if not exists katkit_customers_user_idx on public.katkit_customers(user_id);
create index if not exists katkit_debts_user_idx on public.katkit_debts(user_id,created_at desc);
alter table public.katkit_customers enable row level security;
alter table public.katkit_debts enable row level security;
drop policy if exists "KATKIT users manage own customers" on public.katkit_customers;
create policy "KATKIT users manage own customers" on public.katkit_customers for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "KATKIT users manage own debts" on public.katkit_debts;
create policy "KATKIT users manage own debts" on public.katkit_debts for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
grant select,insert,update,delete on public.katkit_customers to authenticated;
grant select,insert,update,delete on public.katkit_debts to authenticated;
NOTIFY pgrst, 'reload schema';

-- Mise à jour KATKIT : prix d'achat, ventes multi-articles et dépenses
alter table public.katkit_products add column if not exists cost_price numeric(14,2) not null default 0 check(cost_price >= 0);
alter table public.katkit_sales add column if not exists sale_group uuid;
alter table public.katkit_sales add column if not exists customer_id uuid references public.katkit_customers(id) on delete set null;
alter table public.katkit_sales add column if not exists unit_cost numeric(14,2) not null default 0 check(unit_cost >= 0);
create table if not exists public.katkit_expenses (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 description text not null,
 amount numeric(14,2) not null check(amount > 0),
 expense_date date not null default current_date,
 notes text,
 created_at timestamptz not null default now()
);
create index if not exists katkit_expenses_user_date_idx on public.katkit_expenses(user_id,expense_date desc);
alter table public.katkit_expenses enable row level security;
drop policy if exists "KATKIT users manage own expenses" on public.katkit_expenses;
create policy "KATKIT users manage own expenses" on public.katkit_expenses for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
grant select,insert,update,delete on public.katkit_expenses to authenticated;
NOTIFY pgrst, 'reload schema';


-- Mise à jour KATKIT : prix de gros/détail et historique des mouvements de stock
alter table public.katkit_products add column if not exists wholesale_price numeric(14,2) not null default 0 check (wholesale_price >= 0);
update public.katkit_products set wholesale_price = price where wholesale_price = 0 and price > 0;
create table if not exists public.katkit_stock_movements (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 product_id uuid references public.katkit_products(id) on delete set null,
 product_name text not null,
 movement_type text not null check (movement_type in ('entry','exit','sale','return','loss','adjustment')),
 quantity integer not null check (quantity > 0),
 reason text,
 created_at timestamptz not null default now()
);
create index if not exists katkit_stock_movements_user_date_idx on public.katkit_stock_movements(user_id, created_at desc);
alter table public.katkit_stock_movements enable row level security;
drop policy if exists "KATKIT users manage own stock movements" on public.katkit_stock_movements;
create policy "KATKIT users manage own stock movements" on public.katkit_stock_movements for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
grant select, insert, update, delete on public.katkit_stock_movements to authenticated;
NOTIFY pgrst, 'reload schema';


-- KATKIT : signalisation privée WebRTC pour la diffusion vidéo entre appareils du même compte
-- Les canaux privés sont limités à l'identifiant du compte authentifié.
-- Dans Supabase Realtime, activez les canaux privés si ce réglage est disponible.
drop policy if exists "KATKIT own camera signals select" on realtime.messages;
create policy "KATKIT own camera signals select" on realtime.messages
for select to authenticated
using (realtime.topic() = 'katkit-camera:' || (select auth.uid())::text);
drop policy if exists "KATKIT own camera signals insert" on realtime.messages;
create policy "KATKIT own camera signals insert" on realtime.messages
for insert to authenticated
with check (realtime.topic() = 'katkit-camera:' || (select auth.uid())::text);
