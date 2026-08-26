-- =========================================================
-- Grocery Shop Management System - Database Schema
-- PostgreSQL
-- =========================================================

DROP TABLE IF EXISTS stock_movements CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS purchase_items CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

-- =========================================================
-- Reusable trigger function: auto-update `updated_at`
-- Runs before any UPDATE on a table that has this column
-- =========================================================
CREATE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- ROLES
-- =========================================================
CREATE TABLE roles (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

-- =========================================================
-- USERS
-- =========================================================
CREATE TABLE users (
    id         SERIAL PRIMARY KEY,
    full_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,       -- BCrypt hash only, never plain text
    role_id    INTEGER NOT NULL REFERENCES roles(id),
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role_id ON users(role_id);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- CATEGORIES
-- =========================================================
CREATE TABLE categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- PRODUCTS
-- =========================================================
CREATE TABLE products (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(150) NOT NULL,
    sku            VARCHAR(50) NOT NULL UNIQUE,
    category_id    INTEGER REFERENCES categories(id),
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    cost_price     NUMERIC(10,2) NOT NULL CHECK (cost_price >= 0),
    quantity       INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    minimum_stock  INTEGER NOT NULL DEFAULT 5 CHECK (minimum_stock >= 0),
    unit           VARCHAR(20) NOT NULL CHECK (unit IN ('kg','g','litre','ml','piece','bag','dozen')),
    description    TEXT,
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    version        INTEGER NOT NULL DEFAULT 0,   -- optimistic locking for concurrent stock updates (used in Phase 7)
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_sku ON products(sku);

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- SUPPLIERS
-- =========================================================
CREATE TABLE suppliers (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(150),
    address         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- CUSTOMERS
-- =========================================================
CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(150) NOT NULL,
    phone      VARCHAR(20),
    email      VARCHAR(150),
    address    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_phone ON customers(phone);

-- =========================================================
-- PURCHASES (header)
-- =========================================================
CREATE TABLE purchases (
    id             SERIAL PRIMARY KEY,
    supplier_id    INTEGER NOT NULL REFERENCES suppliers(id),
    purchase_date  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    tax            NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
    total          NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'RECEIVED' CHECK (status IN ('RECEIVED','CANCELLED')),
    created_by     INTEGER REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_purchases_supplier_id ON purchases(supplier_id);
CREATE INDEX idx_purchases_purchase_date ON purchases(purchase_date);

-- =========================================================
-- PURCHASE ITEMS (line items)
-- =========================================================
CREATE TABLE purchase_items (
    id           SERIAL PRIMARY KEY,
    purchase_id  INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    product_id   INTEGER NOT NULL REFERENCES products(id),
    quantity     INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost    NUMERIC(10,2) NOT NULL CHECK (unit_cost >= 0),
    line_total   NUMERIC(12,2) NOT NULL CHECK (line_total >= 0)
);

CREATE INDEX idx_purchase_items_purchase_id ON purchase_items(purchase_id);
CREATE INDEX idx_purchase_items_product_id ON purchase_items(product_id);

-- =========================================================
-- SALES (header / invoice)
-- =========================================================
CREATE TABLE sales (
    id              SERIAL PRIMARY KEY,
    invoice_number  VARCHAR(30) NOT NULL UNIQUE,
    customer_id     INTEGER REFERENCES customers(id),
    sale_date       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    discount        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
    tax             NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
    total           NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    status          VARCHAR(20) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('COMPLETED','CANCELLED','REFUNDED')),
    created_by      INTEGER REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sales_customer_id ON sales(customer_id);
CREATE INDEX idx_sales_sale_date ON sales(sale_date);
CREATE INDEX idx_sales_invoice_number ON sales(invoice_number);

-- =========================================================
-- SALE ITEMS (line items)
-- =========================================================
CREATE TABLE sale_items (
    id           SERIAL PRIMARY KEY,
    sale_id      INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id   INTEGER NOT NULL REFERENCES products(id),
    quantity     INTEGER NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total   NUMERIC(12,2) NOT NULL CHECK (line_total >= 0)
);

CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items(product_id);

-- =========================================================
-- PAYMENTS
-- =========================================================
CREATE TABLE payments (
    id        SERIAL PRIMARY KEY,
    sale_id   INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    amount    NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method    VARCHAR(20) NOT NULL CHECK (method IN ('CASH','CARD','UPI','BANK_TRANSFER')),
    paid_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_sale_id ON payments(sale_id);

-- =========================================================
-- EXPENSES
-- =========================================================
CREATE TABLE expenses (
    id            SERIAL PRIMARY KEY,
    category      VARCHAR(50) NOT NULL CHECK (category IN ('RENT','UTILITIES','SALARY','MAINTENANCE','MARKETING','OTHER')),
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    description   TEXT,
    expense_date  DATE NOT NULL,
    created_by    INTEGER REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_expenses_category ON expenses(category);

-- =========================================================
-- STOCK MOVEMENTS (audit trail)
-- =========================================================
CREATE TABLE stock_movements (
    id                SERIAL PRIMARY KEY,
    product_id        INTEGER NOT NULL REFERENCES products(id),
    change_quantity   INTEGER NOT NULL CHECK (change_quantity <> 0),
    movement_type     VARCHAR(20) NOT NULL CHECK (movement_type IN ('PURCHASE','SALE','ADJUSTMENT','RETURN_IN','RETURN_OUT')),
    reference_id      INTEGER,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stock_movements_product_id ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_movement_type ON stock_movements(movement_type);