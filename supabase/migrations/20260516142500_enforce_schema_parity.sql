-- Migration: Enforce NOT NULL constraints and add missing columns to match Dart schema
-- Date: 2026-05-16

-- ==========================================
-- 1. STORE PROFILE
-- ==========================================
-- Add missing columns
ALTER TABLE public.store_profile 
ADD COLUMN IF NOT EXISTS outlet_id uuid,
ADD COLUMN IF NOT EXISTS receipt_footer text,
ADD COLUMN IF NOT EXISTS receipt_header text,
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();

-- Set default values for existing NULL data
UPDATE public.store_profile SET tax_percentage = 0 WHERE tax_percentage IS NULL;
UPDATE public.store_profile SET tax_type = 'exclusive' WHERE tax_type IS NULL;
UPDATE public.store_profile SET service_charge_percentage = 0 WHERE service_charge_percentage IS NULL;
UPDATE public.store_profile SET loyalty_point_conversion = 10000 WHERE loyalty_point_conversion IS NULL;
UPDATE public.store_profile SET loyalty_point_value = 1 WHERE loyalty_point_value IS NULL;
UPDATE public.store_profile SET deduct_stock_on_hold = false WHERE deduct_stock_on_hold IS NULL;
UPDATE public.store_profile SET updated_at = now() WHERE updated_at IS NULL;
UPDATE public.store_profile SET created_at = now() WHERE created_at IS NULL;
UPDATE public.store_profile SET is_dirty = false WHERE is_dirty IS NULL;

-- Apply NOT NULL constraints
ALTER TABLE public.store_profile
ALTER COLUMN tax_percentage SET NOT NULL,
ALTER COLUMN tax_type SET NOT NULL,
ALTER COLUMN service_charge_percentage SET NOT NULL,
ALTER COLUMN loyalty_point_conversion SET NOT NULL,
ALTER COLUMN loyalty_point_value SET NOT NULL,
ALTER COLUMN deduct_stock_on_hold SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN is_dirty SET NOT NULL;

-- ==========================================
-- 2. PRODUCTS
-- ==========================================
-- Set default values for existing NULL data
UPDATE public.products SET stock = 0 WHERE stock IS NULL;
UPDATE public.products SET has_variants = false WHERE has_variants IS NULL;
UPDATE public.products SET purchase_price = 0 WHERE purchase_price IS NULL;
UPDATE public.products SET low_stock_threshold = 0 WHERE low_stock_threshold IS NULL;
UPDATE public.products SET updated_at = now() WHERE updated_at IS NULL;
UPDATE public.products SET created_at = now() WHERE created_at IS NULL;
UPDATE public.products SET is_dirty = false WHERE is_dirty IS NULL;

-- Apply NOT NULL constraints
-- Note: category_id is skipped here because if there's any orphaned data, it will fail. 
-- It should be handled via the UI first.
ALTER TABLE public.products
ALTER COLUMN stock SET NOT NULL,
ALTER COLUMN has_variants SET NOT NULL,
ALTER COLUMN purchase_price SET NOT NULL,
ALTER COLUMN low_stock_threshold SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN is_dirty SET NOT NULL;

-- ==========================================
-- 3. PRODUCT VARIANTS
-- ==========================================
UPDATE public.product_variants SET stock = 0 WHERE stock IS NULL;
UPDATE public.product_variants SET updated_at = now() WHERE updated_at IS NULL;
UPDATE public.product_variants SET created_at = now() WHERE created_at IS NULL;
UPDATE public.product_variants SET is_dirty = false WHERE is_dirty IS NULL;

ALTER TABLE public.product_variants
ALTER COLUMN stock SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN is_dirty SET NOT NULL;

-- ==========================================
-- 4. CATEGORIES
-- ==========================================
UPDATE public.categories SET updated_at = now() WHERE updated_at IS NULL;
UPDATE public.categories SET created_at = now() WHERE created_at IS NULL;
UPDATE public.categories SET is_dirty = false WHERE is_dirty IS NULL;

ALTER TABLE public.categories
ALTER COLUMN updated_at SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN is_dirty SET NOT NULL;
