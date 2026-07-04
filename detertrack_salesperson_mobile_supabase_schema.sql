-- ============================================================
-- DeterTrack Salesperson Mobile App - Supabase Backend Schema
-- Version: 1.0
--
-- This is a focused backend schema for the Flutter salesperson app.
-- If you already ran the full DeterTrack admin schema, you do NOT need
-- to run this whole file again because these tables are already covered.
--
-- Use this file when building only the mobile salesperson MVP backend.
--
-- Main design:
-- - Supabase Auth handles login.
-- - profiles links auth.users to business and role.
-- - salesperson can only access rows where salesperson_id = their ID.
-- - offline mobile app sends local_id and sync_status.
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('admin', 'salesperson');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
    CREATE TYPE public.user_status AS ENUM ('active', 'inactive', 'suspended');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'record_status') THEN
    CREATE TYPE public.record_status AS ENUM ('active', 'inactive', 'deleted');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sale_status') THEN
    CREATE TYPE public.sale_status AS ENUM ('completed', 'partial_payment', 'pending_payment', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_status') THEN
    CREATE TYPE public.sync_status AS ENUM ('synced', 'pending_sync', 'failed', 'conflict');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE public.payment_method AS ENUM ('cash', 'bank_transfer', 'easypaisa', 'jazzcash', 'other');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ledger_transaction_type') THEN
    CREATE TYPE public.ledger_transaction_type AS ENUM ('sale', 'payment', 'return', 'adjustment');
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ============================================================
-- Business and users
-- ============================================================

CREATE TABLE IF NOT EXISTS public.businesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner_name text,
  phone text,
  address text,
  logo_url text,
  currency text NOT NULL DEFAULT 'PKR',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS set_businesses_updated_at ON public.businesses;
CREATE TRIGGER set_businesses_updated_at
BEFORE UPDATE ON public.businesses
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text,
  email citext,
  role public.app_role NOT NULL DEFAULT 'salesperson',
  status public.user_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mobile_profiles_business_id ON public.profiles(business_id);
CREATE INDEX IF NOT EXISTS idx_mobile_profiles_role ON public.profiles(role);

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.salespersons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  profile_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  name text NOT NULL,
  phone text NOT NULL,
  address text,
  can_send_sms boolean NOT NULL DEFAULT true,
  can_delete_customers boolean NOT NULL DEFAULT false,
  can_use_offline boolean NOT NULL DEFAULT true,
  id_card_url text,
  status public.user_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_mobile_salespersons_business_id ON public.salespersons(business_id);
CREATE INDEX IF NOT EXISTS idx_mobile_salespersons_profile_id ON public.salespersons(profile_id);

DROP TRIGGER IF EXISTS set_salespersons_updated_at ON public.salespersons;
CREATE TRIGGER set_salespersons_updated_at
BEFORE UPDATE ON public.salespersons
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

GRANT EXECUTE ON FUNCTION public.sync_sales(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sync_payments(jsonb) TO authenticated;

-- ============================================================
-- Storage Buckets for ID Cards
-- ============================================================

INSERT INTO storage.buckets (id, name, public) 
VALUES ('id_cards', 'id_cards', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Admin can upload ID cards" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (
  bucket_id = 'id_cards' 
  AND (
    SELECT role FROM public.profiles WHERE id = auth.uid()
  ) = 'admin'
);

CREATE POLICY "Anyone can view ID cards" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'id_cards');

-- ============================================================
-- Villages and customers
-- ============================================================

CREATE TABLE IF NOT EXISTS public.villages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE RESTRICT,
  name text NOT NULL,
  notes text,
  status public.record_status NOT NULL DEFAULT 'active',
  local_id text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE public.villages ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.villages ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE INDEX IF NOT EXISTS idx_mobile_villages_salesperson_id ON public.villages(salesperson_id);
CREATE INDEX IF NOT EXISTS idx_mobile_villages_business_id ON public.villages(business_id);
CREATE INDEX IF NOT EXISTS idx_mobile_villages_sync_status ON public.villages(sync_status);

DROP TRIGGER IF EXISTS set_villages_updated_at ON public.villages;
CREATE TRIGGER set_villages_updated_at
BEFORE UPDATE ON public.villages
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE RESTRICT,
  village_id uuid NOT NULL REFERENCES public.villages(id) ON DELETE RESTRICT,
  name text NOT NULL,
  phone text,
  house_number text,
  address text,
  total_sales numeric(14,2) NOT NULL DEFAULT 0,
  total_paid numeric(14,2) NOT NULL DEFAULT 0,
  total_pending numeric(14,2) NOT NULL DEFAULT 0,
  last_purchase_date timestamptz,
  last_payment_date timestamptz,
  status public.record_status NOT NULL DEFAULT 'active',
  notes text,
  local_id text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE UNIQUE INDEX IF NOT EXISTS uniq_mobile_customer_phone_per_village
ON public.customers(business_id, village_id, phone)
WHERE phone IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mobile_customers_salesperson_id ON public.customers(salesperson_id);
CREATE INDEX IF NOT EXISTS idx_mobile_customers_village_id ON public.customers(village_id);
CREATE INDEX IF NOT EXISTS idx_mobile_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_mobile_customers_name ON public.customers(lower(name));
CREATE INDEX IF NOT EXISTS idx_mobile_customers_sync_status ON public.customers(sync_status);

DROP TRIGGER IF EXISTS set_customers_updated_at ON public.customers;
CREATE TRIGGER set_customers_updated_at
BEFORE UPDATE ON public.customers
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- Products and inventory for mobile
-- ============================================================

CREATE TABLE IF NOT EXISTS public.product_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  status public.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id uuid REFERENCES public.product_categories(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  status public.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  size_label text NOT NULL,
  unit text NOT NULL DEFAULT 'pcs',
  sku text,
  sale_price numeric(14,2) NOT NULL DEFAULT 0,
  cost_price numeric(14,2) NOT NULL DEFAULT 0,
  low_stock_threshold numeric(14,2) NOT NULL DEFAULT 0,
  status public.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.salesperson_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE RESTRICT,
  quantity_received numeric(14,2) NOT NULL DEFAULT 0,
  quantity_sold numeric(14,2) NOT NULL DEFAULT 0,
  quantity_returned numeric(14,2) NOT NULL DEFAULT 0,
  quantity_damaged numeric(14,2) NOT NULL DEFAULT 0,
  remaining_quantity numeric(14,2) NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_mobile_salesperson_inventory_variant
ON public.salesperson_inventory(business_id, salesperson_id, variant_id);

-- ============================================================
-- Sales, payments, ledger
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE RESTRICT,
  village_id uuid NOT NULL REFERENCES public.villages(id) ON DELETE RESTRICT,
  sale_date timestamptz NOT NULL DEFAULT now(),
  previous_pending numeric(14,2) NOT NULL DEFAULT 0,
  total_amount numeric(14,2) NOT NULL DEFAULT 0,
  paid_amount numeric(14,2) NOT NULL DEFAULT 0,
  new_pending numeric(14,2) NOT NULL DEFAULT 0,
  sale_status public.sale_status NOT NULL DEFAULT 'completed',
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  local_id text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE INDEX IF NOT EXISTS idx_mobile_sales_salesperson_id ON public.sales(salesperson_id);
CREATE INDEX IF NOT EXISTS idx_mobile_sales_customer_id ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_mobile_sales_date ON public.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_mobile_sales_sync_status ON public.sales(sync_status);

CREATE TABLE IF NOT EXISTS public.sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE RESTRICT,
  quantity numeric(14,2) NOT NULL,
  unit_price numeric(14,2) NOT NULL,
  total_price numeric(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  local_id text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE RESTRICT,
  source_sale_id uuid REFERENCES public.sales(id) ON DELETE SET NULL,
  amount numeric(14,2) NOT NULL,
  payment_date timestamptz NOT NULL DEFAULT now(),
  payment_method public.payment_method NOT NULL DEFAULT 'cash',
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  local_id text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE INDEX IF NOT EXISTS idx_mobile_payments_salesperson_id ON public.payments(salesperson_id);
CREATE INDEX IF NOT EXISTS idx_mobile_payments_customer_id ON public.payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_mobile_payments_sync_status ON public.payments(sync_status);

CREATE TABLE IF NOT EXISTS public.customer_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  salesperson_id uuid REFERENCES public.salespersons(id) ON DELETE SET NULL,
  transaction_type public.ledger_transaction_type NOT NULL,
  sale_id uuid REFERENCES public.sales(id) ON DELETE SET NULL,
  payment_id uuid REFERENCES public.payments(id) ON DELETE SET NULL,
  debit_amount numeric(14,2) NOT NULL DEFAULT 0,
  credit_amount numeric(14,2) NOT NULL DEFAULT 0,
  balance_after numeric(14,2) NOT NULL DEFAULT 0,
  transaction_date timestamptz NOT NULL DEFAULT now(),
  notes text,
  local_id text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.customer_ledger ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.customer_ledger ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE INDEX IF NOT EXISTS idx_mobile_ledger_customer_id ON public.customer_ledger(customer_id);
CREATE INDEX IF NOT EXISTS idx_mobile_ledger_salesperson_id ON public.customer_ledger(salesperson_id);
CREATE INDEX IF NOT EXISTS idx_mobile_ledger_sync_status ON public.customer_ledger(sync_status);

-- ============================================================
-- Inventory returns, receipts, notifications, sync logs
-- ============================================================

CREATE TABLE IF NOT EXISTS public.inventory_returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  salesperson_id uuid NOT NULL REFERENCES public.salespersons(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE RESTRICT,
  quantity_returned numeric(14,2) NOT NULL,
  return_date timestamptz NOT NULL DEFAULT now(),
  reason text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  local_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_returns ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.inventory_returns ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE TABLE IF NOT EXISTS public.receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  receipt_number text NOT NULL,
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  sale_id uuid REFERENCES public.sales(id) ON DELETE SET NULL,
  payment_id uuid REFERENCES public.payments(id) ON DELETE SET NULL,
  salesperson_id uuid REFERENCES public.salespersons(id) ON DELETE SET NULL,
  receipt_type text NOT NULL DEFAULT 'sale',
  total_amount numeric(14,2) NOT NULL DEFAULT 0,
  paid_amount numeric(14,2) NOT NULL DEFAULT 0,
  pending_amount numeric(14,2) NOT NULL DEFAULT 0,
  pdf_url text,
  local_id text,
  sync_status public.sync_status NOT NULL DEFAULT 'synced',
  generated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.receipts ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.receipts ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL DEFAULT 'system',
  read_status boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.offline_sync_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  salesperson_id uuid REFERENCES public.salespersons(id) ON DELETE SET NULL,
  record_type text NOT NULL,
  local_id text,
  server_id uuid,
  sync_status public.sync_status NOT NULL DEFAULT 'pending_sync',
  error_message text,
  payload jsonb,
  synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.offline_sync_logs ADD COLUMN IF NOT EXISTS local_id text;
ALTER TABLE public.offline_sync_logs ADD COLUMN IF NOT EXISTS sync_status public.sync_status NOT NULL DEFAULT 'pending_sync';

-- ============================================================
-- Auth helper functions
-- ============================================================

CREATE OR REPLACE FUNCTION public.current_business_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.business_id FROM public.profiles p WHERE p.id = auth.uid() LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
      AND p.status = 'active'
  )
$$;

CREATE OR REPLACE FUNCTION public.current_salesperson_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.id
  FROM public.salespersons s
  JOIN public.profiles p ON p.id = s.profile_id
  WHERE p.id = auth.uid()
    AND s.status = 'active'
  LIMIT 1
$$;

-- ============================================================
-- Basic customer balance functions
-- ============================================================

CREATE OR REPLACE FUNCTION public.recalculate_customer_totals(p_customer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_debit numeric(14,2);
  v_total_credit numeric(14,2);
BEGIN
  SELECT COALESCE(SUM(debit_amount),0), COALESCE(SUM(credit_amount),0)
  INTO v_total_debit, v_total_credit
  FROM public.customer_ledger
  WHERE customer_id = p_customer_id;

  UPDATE public.customers
  SET
    total_sales = v_total_debit,
    total_paid = v_total_credit,
    total_pending = GREATEST(v_total_debit - v_total_credit, 0),
    updated_at = now()
  WHERE id = p_customer_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.after_ledger_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.recalculate_customer_totals(COALESCE(NEW.customer_id, OLD.customer_id));
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS after_mobile_ledger_change ON public.customer_ledger;
CREATE TRIGGER after_mobile_ledger_change
AFTER INSERT OR UPDATE OR DELETE ON public.customer_ledger
FOR EACH ROW EXECUTE FUNCTION public.after_ledger_change();

-- ============================================================
-- RLS
-- ============================================================

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salespersons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.villages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salesperson_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_sync_logs ENABLE ROW LEVEL SECURITY;

-- Businesses / profiles
CREATE POLICY "mobile_business_select_same_business"
ON public.businesses FOR SELECT TO authenticated
USING (id = public.current_business_id());

CREATE POLICY "mobile_profiles_select_same_business"
ON public.profiles FOR SELECT TO authenticated
USING (business_id = public.current_business_id());

-- Salespersons
CREATE POLICY "mobile_salesperson_select_admin_or_own"
ON public.salespersons FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR id = public.current_salesperson_id()
);

-- Villages
CREATE POLICY "mobile_villages_select_admin_or_own"
ON public.villages FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_villages_insert_own"
ON public.villages FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_villages_update_own"
ON public.villages FOR UPDATE TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
)
WITH CHECK (
  business_id = public.current_business_id()
  AND (
    public.is_admin()
    OR salesperson_id = public.current_salesperson_id()
  )
);

-- Customers
CREATE POLICY "mobile_customers_select_admin_or_own"
ON public.customers FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_customers_insert_own"
ON public.customers FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_customers_update_own"
ON public.customers FOR UPDATE TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
)
WITH CHECK (
  business_id = public.current_business_id()
  AND (
    public.is_admin()
    OR salesperson_id = public.current_salesperson_id()
  )
);

-- Products read-only for salesperson
CREATE POLICY "mobile_categories_read_same_business"
ON public.product_categories FOR SELECT TO authenticated
USING (business_id = public.current_business_id());

CREATE POLICY "mobile_products_read_same_business"
ON public.products FOR SELECT TO authenticated
USING (business_id = public.current_business_id());

CREATE POLICY "mobile_variants_read_same_business"
ON public.product_variants FOR SELECT TO authenticated
USING (business_id = public.current_business_id());

-- Inventory
CREATE POLICY "mobile_salesperson_inventory_select_own"
ON public.salesperson_inventory FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

-- Sales / payments / ledger
CREATE POLICY "mobile_sales_select_own"
ON public.sales FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_sales_insert_own"
ON public.sales FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_sale_items_select_own"
ON public.sale_items FOR SELECT TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.sales s
    WHERE s.id = sale_items.sale_id
      AND s.salesperson_id = public.current_salesperson_id()
  )
);

CREATE POLICY "mobile_sale_items_insert_own"
ON public.sale_items FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND EXISTS (
    SELECT 1 FROM public.sales s
    WHERE s.id = sale_items.sale_id
      AND s.salesperson_id = public.current_salesperson_id()
  )
);

CREATE POLICY "mobile_payments_select_own"
ON public.payments FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_payments_insert_own"
ON public.payments FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_ledger_select_own"
ON public.customer_ledger FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_ledger_insert_own"
ON public.customer_ledger FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

-- Returns / receipts / notifications / sync
CREATE POLICY "mobile_inventory_returns_select_own"
ON public.inventory_returns FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_inventory_returns_insert_own"
ON public.inventory_returns FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_receipts_select_own"
ON public.receipts FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_receipts_insert_own"
ON public.receipts FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_notifications_select_own"
ON public.notifications FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR (public.is_admin() AND business_id = public.current_business_id())
);

CREATE POLICY "mobile_sync_logs_select_own"
ON public.offline_sync_logs FOR SELECT TO authenticated
USING (
  (public.is_admin() AND business_id = public.current_business_id())
  OR user_id = auth.uid()
  OR salesperson_id = public.current_salesperson_id()
);

CREATE POLICY "mobile_sync_logs_insert_own"
ON public.offline_sync_logs FOR INSERT TO authenticated
WITH CHECK (
  business_id = public.current_business_id()
  AND (
    user_id = auth.uid()
    OR salesperson_id = public.current_salesperson_id()
  )
);

COMMIT;
