CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    phone text,
    email text,
    address text,
    is_member boolean DEFAULT true,
    points integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.discounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    scope text DEFAULT 'transaction'::text,
    type text DEFAULT 'percentage'::text,
    value real NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    min_spend integer DEFAULT 0,
    min_qty integer DEFAULT 1,
    is_automatic boolean DEFAULT false,
    is_stackable boolean DEFAULT true,
    start_date timestamp with time zone,
    end_date timestamp with time zone
);

CREATE TABLE public.employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    pin text NOT NULL,
    role text NOT NULL,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    failed_login_attempts integer DEFAULT 0,
    locked_until timestamp with time zone,
    photo_uri text
);

CREATE TABLE public.expense_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    icon text DEFAULT 'shopping_bag'::text,
    color text DEFAULT '#1E3A5F'::text,
    is_default boolean DEFAULT false
);

CREATE TABLE public.expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    category_id uuid,
    amount bigint NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    shift_id uuid,
    recorded_by uuid,
    photo_uri text
);

CREATE TABLE public.ingredient_stock_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ingredient_id uuid NOT NULL,
    outlet_id uuid,
    type text NOT NULL,
    quantity_change real NOT NULL,
    previous_balance real NOT NULL,
    new_balance real NOT NULL,
    reference_id text,
    supplier_id uuid,
    reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    unit text NOT NULL,
    stock_quantity real DEFAULT 0.0,
    min_stock_threshold real DEFAULT 0.0,
    average_cost real DEFAULT 0,
    last_supplier_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.landing_page_settings (
    id text DEFAULT 'main_page'::text NOT NULL,
    content jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.license_devices (
    id integer NOT NULL,
    license_id bigint,
    device_fingerprint text NOT NULL,
    device_model text,
    os_version text,
    activation_date timestamp with time zone,
    last_verified_at timestamp with time zone,
    created_at timestamp with time zone
);

CREATE TABLE public.licenses (
    id integer NOT NULL,
    license_code text NOT NULL,
    tier_level text DEFAULT 'Tier 1 - Lifetime'::character varying,
    max_devices integer DEFAULT 1,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    customer_email text,
    order_id text,
    source text,
    max_outlets bigint DEFAULT 1,
    user_id uuid,
    expired_at timestamp with time zone
);

CREATE TABLE public.mapping_skus (
    id integer NOT NULL,
    marketplace_sku text NOT NULL,
    tier_level text NOT NULL,
    max_devices integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.outlets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    address text,
    phone text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.printer_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    device_name text,
    mac_address text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    status text DEFAULT 'paired'::text,
    auto_print boolean DEFAULT false
);

CREATE TABLE public.product_recipes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    ingredient_id uuid,
    quantity_needed real NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.product_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    name text NOT NULL,
    option_value text NOT NULL,
    price bigint,
    stock integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    outlet_id uuid,
    sku text
);

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    category_id uuid,
    name text NOT NULL,
    sku text,
    price bigint NOT NULL,
    stock integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    has_variants boolean DEFAULT false,
    purchase_price integer DEFAULT 0,
    low_stock_threshold integer DEFAULT 0,
    image_uri text
);

CREATE TABLE public.purchase_order_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    purchase_order_id uuid,
    outlet_id uuid,
    product_id uuid,
    ingredient_id uuid,
    item_name text NOT NULL,
    unit text NOT NULL,
    quantity numeric NOT NULL,
    purchase_price integer DEFAULT 0,
    received_quantity numeric DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    is_dirty boolean DEFAULT false
);

CREATE TABLE public.purchase_orders (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    outlet_id uuid,
    supplier_id uuid,
    status text DEFAULT 'draft'::text,
    total_estimate integer DEFAULT 0,
    notes text,
    ordered_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    is_dirty boolean DEFAULT false
);

CREATE TABLE public.shifts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    employee_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    starting_cash bigint DEFAULT 0,
    actual_ending_cash bigint,
    status text DEFAULT 'open'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    expected_ending_cash bigint
);

CREATE TABLE public.stock_opname (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    outlet_id uuid,
    opname_number text NOT NULL,
    type text NOT NULL,
    status text NOT NULL,
    created_by text,
    notes text,
    variance_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    is_dirty boolean DEFAULT false
);

CREATE TABLE public.stock_opname_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    stock_opname_id uuid,
    outlet_id uuid,
    product_id uuid,
    variant_id uuid,
    ingredient_id uuid,
    system_stock numeric NOT NULL,
    physical_stock numeric NOT NULL,
    variance numeric NOT NULL,
    variance_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    is_dirty boolean DEFAULT false
);

CREATE TABLE public.stock_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    product_id uuid,
    type text NOT NULL,
    quantity integer NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    variant_id uuid,
    supplier_id uuid,
    previous_stock integer,
    new_stock integer,
    reference text
);

CREATE TABLE public.store_profile (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text DEFAULT ''::text NOT NULL,
    address text,
    phone text,
    logo_uri text,
    tax_percentage integer DEFAULT 0,
    tax_type text DEFAULT 'exclusive'::text,
    service_charge_percentage integer DEFAULT 0,
    receipt_footer text,
    receipt_header text,
    loyalty_point_conversion integer DEFAULT 10000,
    loyalty_point_value integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    deduct_stock_on_hold boolean DEFAULT false,
    user_id uuid,
    business_type text
);

CREATE TABLE public.suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    name text NOT NULL,
    phone text,
    address text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone
);

CREATE TABLE public.transaction_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid,
    product_id uuid,
    variant_id uuid,
    quantity integer NOT NULL,
    price_at_transaction bigint NOT NULL,
    subtotal bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    outlet_id uuid,
    variant_name text,
    discount_id uuid,
    discount_amount bigint DEFAULT 0
);

CREATE TABLE public.transaction_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid,
    method text NOT NULL,
    amount bigint NOT NULL,
    change_given bigint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    outlet_id uuid
);

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    shift_id uuid,
    receipt_number text,
    total_amount bigint NOT NULL,
    payment_method text,
    payment_status text DEFAULT 'paid'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    subtotal bigint DEFAULT 0 NOT NULL,
    tax_amount bigint DEFAULT 0 NOT NULL,
    service_charge_amount bigint DEFAULT 0 NOT NULL,
    void_by uuid,
    customer_id uuid,
    customer_phone text,
    customer_name text,
    discount_id uuid,
    discount_amount bigint DEFAULT 0,
    points_earned integer DEFAULT 0,
    points_redeemed integer DEFAULT 0,
    notes text
);

CREATE TABLE public.unit_conversions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    outlet_id uuid,
    from_unit text NOT NULL,
    to_unit text NOT NULL,
    multiplier real NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_dirty boolean DEFAULT false,
    deleted_at timestamp with time zone,
    notes text
);

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role text DEFAULT 'owner'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_roles_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'owner'::text])))
);

CREATE TABLE public.users (
    id bigint NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);