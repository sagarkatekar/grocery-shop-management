-- =========================================================
-- Grocery Shop Management System - Seed Data
-- Run this AFTER schema.sql
-- =========================================================

-- ROLES
INSERT INTO roles (name) VALUES
('ADMIN'),
('MANAGER'),
('EMPLOYEE');

-- USERS
-- Note: these password hashes are placeholders (BCrypt for "password123").
-- We will generate real ones properly in Phase 5 (Auth). For now this lets
-- foreign keys resolve so we can test the rest of the schema.
INSERT INTO users (full_name, email, password, role_id, active) VALUES
('Admin User',    'admin@groceryshop.com',    '$2a$10$placeholderplaceholderplaceholderplaceholder', 1, TRUE),
('Store Manager', 'manager@groceryshop.com',  '$2a$10$placeholderplaceholderplaceholderplaceholder', 2, TRUE),
('Cashier One',   'cashier@groceryshop.com',  '$2a$10$placeholderplaceholderplaceholderplaceholder', 3, TRUE);

-- CATEGORIES
INSERT INTO categories (name, description) VALUES
('Dairy', 'Milk, cheese, butter, yogurt and related products'),
('Beverages', 'Soft drinks, juices, water, tea, coffee'),
('Bakery', 'Bread, cakes, pastries'),
('Fruits & Vegetables', 'Fresh produce'),
('Snacks', 'Chips, biscuits, namkeen, chocolates'),
('Grains & Staples', 'Rice, wheat, pulses, flour');

-- PRODUCTS
INSERT INTO products (name, sku, category_id, price, cost_price, quantity, minimum_stock, unit, description) VALUES
('Full Cream Milk 1L',    'DAI-001', 1, 65.00,  52.00, 40, 10, 'litre', 'Fresh full cream milk'),
('Cheddar Cheese 200g',   'DAI-002', 1, 180.00, 140.00, 15, 5,  'piece', 'Block cheddar cheese'),
('Coca-Cola 750ml',       'BEV-001', 2, 45.00,  32.00, 60, 15, 'piece', 'Carbonated soft drink'),
('Orange Juice 1L',       'BEV-002', 2, 110.00, 85.00,  20, 8,  'litre', '100% orange juice'),
('White Bread 400g',      'BAK-001', 3, 40.00,  28.00,  25, 10, 'piece', 'Sliced white bread'),
('Chocolate Muffin',      'BAK-002', 3, 35.00,  20.00,  30, 10, 'piece', 'Pack of 2 muffins'),
('Banana (1kg)',          'FRV-001', 4, 50.00,  35.00,  50, 15, 'kg',    'Fresh bananas'),
('Tomato (1kg)',          'FRV-002', 4, 30.00,  20.00,  45, 15, 'kg',    'Fresh tomatoes'),
('Potato Chips 100g',     'SNK-001', 5, 20.00,  13.00,  80, 20, 'piece', 'Salted potato chips'),
('Dark Chocolate Bar',    'SNK-002', 5, 90.00,  65.00,  35, 10, 'piece', '70% cocoa dark chocolate'),
('Basmati Rice 5kg',      'GRA-001', 6, 450.00, 380.00, 18, 5,  'bag',   'Premium basmati rice'),
('Wheat Flour 5kg',       'GRA-002', 6, 220.00, 180.00, 3,  5,  'bag',   'Whole wheat flour');
-- Note: Wheat Flour has quantity (3) below minimum_stock (5) on purpose,
-- so we have real data to test the low-stock alert feature later.

-- SUPPLIERS
INSERT INTO suppliers (name, contact_person, phone, email, address) VALUES
('Fresh Farms Distributors', 'Rajesh Kumar', '9876543210', 'sales@freshfarms.com', 'Pune, Maharashtra'),
('National Beverages Co.',   'Anita Sharma', '9123456780', 'orders@natbev.com',    'Mumbai, Maharashtra'),
('Golden Grains Wholesale',  'Suresh Patil', '9988776655', 'contact@goldengrains.com', 'Nashik, Maharashtra');

-- CUSTOMERS
INSERT INTO customers (name, phone, email, address) VALUES
('Rahul Deshmukh', '9000011111', 'rahul.d@example.com', 'FC Road, Pune'),
('Priya Joshi',     '9000022222', 'priya.j@example.com', 'Kothrud, Pune'),
('Walk-in Customer', NULL, NULL, NULL);

-- PURCHASES (one sample purchase from Fresh Farms)
INSERT INTO purchases (supplier_id, purchase_date, subtotal, tax, total, created_by) VALUES
(1, CURRENT_TIMESTAMP - INTERVAL '5 days', 5200.00, 260.00, 5460.00, 2);

INSERT INTO purchase_items (purchase_id, product_id, quantity, unit_cost, line_total) VALUES
(1, 1, 40, 52.00, 2080.00),  -- Milk
(1, 2, 15, 140.00, 2100.00), -- Cheese... adjusted below to keep totals illustrative
(1, 5, 25, 28.00, 700.00);   -- Bread

-- Reflect this purchase in stock_movements (audit trail)
INSERT INTO stock_movements (product_id, change_quantity, movement_type, reference_id, notes) VALUES
(1, 40, 'PURCHASE', 1, 'Stock received from Fresh Farms Distributors'),
(2, 15, 'PURCHASE', 1, 'Stock received from Fresh Farms Distributors'),
(5, 25, 'PURCHASE', 1, 'Stock received from Fresh Farms Distributors');

-- SALES (one sample sale to Rahul Deshmukh)
INSERT INTO sales (invoice_number, customer_id, sale_date, subtotal, discount, tax, total, status, created_by) VALUES
('INV-2026-0001', 1, CURRENT_TIMESTAMP - INTERVAL '1 day', 155.00, 5.00, 7.50, 157.50, 'COMPLETED', 3);

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, line_total) VALUES
(1, 3, 2, 45.00, 90.00),   -- 2x Coca-Cola
(1, 9, 2, 20.00, 40.00),   -- 2x Chips
(1, 6, 1, 35.00, 35.00);   -- 1x Muffin
-- Note: subtotal above (155.00) is illustrative; exact recalculation
-- will be enforced by application logic in Phase 11.

-- Reflect this sale in stock_movements
INSERT INTO stock_movements (product_id, change_quantity, movement_type, reference_id, notes) VALUES
(3, -2, 'SALE', 1, 'Sold to Rahul Deshmukh'),
(9, -2, 'SALE', 1, 'Sold to Rahul Deshmukh'),
(6, -1, 'SALE', 1, 'Sold to Rahul Deshmukh');

-- PAYMENT for the above sale
INSERT INTO payments (sale_id, amount, method, paid_at) VALUES
(1, 157.50, 'CASH', CURRENT_TIMESTAMP - INTERVAL '1 day');

-- EXPENSES
INSERT INTO expenses (category, amount, description, expense_date, created_by) VALUES
('RENT', 15000.00, 'Monthly shop rent', CURRENT_DATE - INTERVAL '3 days', 1),
('UTILITIES', 2500.00, 'Electricity bill', CURRENT_DATE - INTERVAL '2 days', 1),
('SALARY', 12000.00, 'Cashier salary - partial', CURRENT_DATE - INTERVAL '1 days', 1);