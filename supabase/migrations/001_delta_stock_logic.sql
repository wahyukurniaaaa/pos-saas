-- ==============================================================================
-- Migration: Delta Stock Logic Triggers
-- Purpose: Mengkalkulasi `stock` pada tabel `products` dan `product_variants`
--          berdasarkan akumulasi row insert di tabel `stock_transactions`.
-- ==============================================================================

-- 1. Fungsi & Trigger untuk Produk Utama
CREATE OR REPLACE FUNCTION sync_product_stock()
RETURNS TRIGGER AS $$
BEGIN
  -- Kolom quantity di stock_transactions menggunakan integer bertanda.
  -- Penambahan / penerimaan PO = positif.
  -- Penjualan = negatif.
  UPDATE products
  SET stock = stock + NEW.quantity
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_product_stock ON stock_transactions;
CREATE TRIGGER trg_sync_product_stock
AFTER INSERT ON stock_transactions
FOR EACH ROW
EXECUTE PROCEDURE sync_product_stock();


-- 2. Fungsi & Trigger untuk Product Variants (Jika ada)
CREATE OR REPLACE FUNCTION sync_variant_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.variant_id IS NOT NULL THEN
    UPDATE product_variants
    SET stock = stock + NEW.quantity
    WHERE id = NEW.variant_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_variant_stock ON stock_transactions;
CREATE TRIGGER trg_sync_variant_stock
AFTER INSERT ON stock_transactions
FOR EACH ROW
EXECUTE PROCEDURE sync_variant_stock();
