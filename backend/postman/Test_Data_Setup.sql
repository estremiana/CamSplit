-- CamSplit Test Data Setup
-- This file contains sample data for testing the API endpoints
-- Run this after the initial database setup to populate with test data

-- Clear existing data (optional - only if you want fresh test data)
-- DELETE FROM assignment_users;
-- DELETE FROM assignments;
-- DELETE FROM items;
-- DELETE FROM payments;
-- DELETE FROM expense_splits;
-- DELETE FROM expense_payers;
-- DELETE FROM expenses;
-- DELETE FROM group_members;
-- DELETE FROM groups;
-- DELETE FROM users;

-- Insert test users
INSERT INTO users (email, password_hash, name, birthdate, created_at, updated_at) VALUES
('john.doe@example.com', '$2b$10$example.hash.here', 'John Doe', '1990-01-01', NOW(), NOW()),
('jane.smith@example.com', '$2b$10$example.hash.here', 'Jane Smith', '1992-05-15', NOW(), NOW()),
('bob.wilson@example.com', '$2b$10$example.hash.here', 'Bob Wilson', '1988-12-10', NOW(), NOW());

-- Insert test groups
INSERT INTO groups (name, description, currency, created_by, created_at, updated_at) VALUES
('Roommates', 'Monthly apartment expenses', 'EUR', 1, NOW(), NOW()),
('Work Team', 'Team lunch and coffee expenses', 'EUR', 1, NOW(), NOW()),
('Vacation Group', 'Holiday expenses', 'EUR', 2, NOW(), NOW());

-- Insert group members
INSERT INTO group_members (group_id, user_id, nickname, email, role, is_registered_user, joined_at) VALUES
-- Roommates group
(1, 1, 'John', 'john.doe@example.com', 'admin', true, NOW()),
(1, 2, 'Jane', 'jane.smith@example.com', 'member', true, NOW()),
(1, NULL, 'Bob Roommate', 'bob.roommate@example.com', 'member', false, NOW()),

-- Work Team group
(2, 1, 'John', 'john.doe@example.com', 'admin', true, NOW()),
(2, 2, 'Jane', 'jane.smith@example.com', 'member', true, NOW()),
(2, 3, 'Bob', 'bob.wilson@example.com', 'member', true, NOW()),

-- Vacation Group
(3, 2, 'Jane', 'jane.smith@example.com', 'admin', true, NOW()),
(3, 1, 'John', 'john.doe@example.com', 'member', true, NOW());

-- Insert test expenses
INSERT INTO expenses (title, total_amount, currency, date, category, notes, group_id, split_type, created_by, created_at, updated_at) VALUES
-- Simple expenses
('Rent Payment', 1200.00, 'EUR', '2024-01-01', 'Housing', 'Monthly rent payment', 1, 'equal', 1, NOW(), NOW()),
('Electricity Bill', 150.00, 'EUR', '2024-01-05', 'Utilities', 'Monthly electricity', 1, 'equal', 1, NOW(), NOW()),
('Team Lunch', 85.50, 'EUR', '2024-01-10', 'Food & Dining', 'Team lunch at restaurant', 2, 'equal', 1, NOW(), NOW()),

-- Complex expenses (with items)
('Grocery Shopping', 150.00, 'EUR', '2024-01-15', 'Food', 'Weekly groceries', 1, 'custom', 1, NOW(), NOW()),
('Coffee Run', 45.00, 'EUR', '2024-01-12', 'Food & Dining', 'Office coffee and snacks', 2, 'custom', 1, NOW(), NOW());

-- Insert expense payers
INSERT INTO expense_payers (expense_id, group_member_id, amount_paid, payment_method, payment_date, created_at) VALUES
-- Rent payment
(1, 1, 1200.00, 'bank_transfer', NOW(), NOW()),

-- Electricity bill
(2, 1, 150.00, 'card', NOW(), NOW()),

-- Team lunch
(3, 1, 85.50, 'card', NOW(), NOW()),

-- Grocery shopping
(4, 1, 150.00, 'card', NOW(), NOW()),

-- Coffee run
(5, 1, 45.00, 'cash', NOW(), NOW());

-- Insert expense splits
INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, created_at) VALUES
-- Rent payment (equal split)
(1, 1, 600.00, NOW()),
(1, 2, 600.00, NOW()),

-- Electricity bill (equal split)
(2, 1, 75.00, NOW()),
(2, 2, 75.00, NOW()),

-- Team lunch (equal split)
(3, 1, 28.50, NOW()),
(3, 2, 28.50, NOW()),
(3, 3, 28.50, NOW()),

-- Grocery shopping (custom split)
(4, 1, 50.00, NOW()),
(4, 2, 100.00, NOW()),

-- Coffee run (custom split)
(5, 1, 15.00, NOW()),
(5, 2, 20.00, NOW()),
(5, 3, 10.00, NOW());

-- Insert items for complex expenses
INSERT INTO items (expense_id, name, description, unit_price, max_quantity, total_price, category, created_at, updated_at) VALUES
-- Grocery shopping items
(4, 'Milk', 'Organic whole milk', 3.50, 2, 7.00, 'Dairy', NOW(), NOW()),
(4, 'Bread', 'Whole wheat bread', 2.50, 1, 2.50, 'Bakery', NOW(), NOW()),
(4, 'Cheese', 'Cheddar cheese', 5.00, 1, 5.00, 'Dairy', NOW(), NOW()),
(4, 'Apples', 'Red apples', 2.00, 3, 6.00, 'Produce', NOW(), NOW()),
(4, 'Chicken', 'Chicken breast', 12.00, 2, 24.00, 'Meat', NOW(), NOW()),

-- Coffee run items
(5, 'Coffee', 'Espresso', 3.50, 5, 17.50, 'Beverages', NOW(), NOW()),
(5, 'Cappuccino', 'Cappuccino', 4.00, 3, 12.00, 'Beverages', NOW(), NOW()),
(5, 'Croissant', 'Butter croissant', 2.50, 4, 10.00, 'Bakery', NOW(), NOW()),
(5, 'Muffin', 'Blueberry muffin', 3.00, 2, 6.00, 'Bakery', NOW(), NOW());

-- Insert assignments for items
INSERT INTO assignments (expense_id, item_id, quantity, unit_price, total_price, people_count, price_per_person, notes, created_at, updated_at) VALUES
-- Grocery assignments
(4, 1, 1, 3.50, 3.50, 2, 1.75, 'Shared between John and Jane', NOW(), NOW()),
(4, 1, 1, 3.50, 3.50, 1, 3.50, 'John only', NOW(), NOW()),
(4, 2, 1, 2.50, 2.50, 1, 2.50, 'Jane only', NOW(), NOW()),
(4, 3, 1, 5.00, 5.00, 2, 2.50, 'Shared between John and Bob', NOW(), NOW()),
(4, 4, 2, 2.00, 4.00, 2, 2.00, 'Shared between John and Jane', NOW(), NOW()),
(4, 4, 1, 2.00, 2.00, 1, 2.00, 'Bob only', NOW(), NOW()),
(4, 5, 1, 12.00, 12.00, 2, 6.00, 'Shared between John and Jane', NOW(), NOW()),
(4, 5, 1, 12.00, 12.00, 1, 12.00, 'Bob only', NOW(), NOW()),

-- Coffee assignments
(5, 6, 2, 3.50, 7.00, 2, 3.50, 'John and Jane', NOW(), NOW()),
(5, 6, 3, 3.50, 10.50, 3, 3.50, 'All three', NOW(), NOW()),
(5, 7, 2, 4.00, 8.00, 2, 4.00, 'John and Bob', NOW(), NOW()),
(5, 7, 1, 4.00, 4.00, 1, 4.00, 'Jane only', NOW(), NOW()),
(5, 8, 2, 2.50, 5.00, 2, 2.50, 'John and Jane', NOW(), NOW()),
(5, 8, 2, 2.50, 5.00, 2, 2.50, 'Bob and Jane', NOW(), NOW()),
(5, 9, 1, 3.00, 3.00, 1, 3.00, 'John only', NOW(), NOW()),
(5, 9, 1, 3.00, 3.00, 1, 3.00, 'Bob only', NOW(), NOW());

-- Insert assignment users (many-to-many relationship)
INSERT INTO assignment_users (assignment_id, group_member_id, created_at) VALUES
-- Grocery assignments
(1, 1, NOW()), (1, 2, NOW()),  -- Milk shared between John and Jane
(2, 1, NOW()),                 -- Milk for John only
(3, 2, NOW()),                 -- Bread for Jane only
(4, 1, NOW()), (4, 3, NOW()),  -- Cheese shared between John and Bob
(5, 1, NOW()), (5, 2, NOW()),  -- Apples shared between John and Jane
(6, 3, NOW()),                 -- Apple for Bob only
(7, 1, NOW()), (7, 2, NOW()),  -- Chicken shared between John and Jane
(8, 3, NOW()),                 -- Chicken for Bob only

-- Coffee assignments
(9, 1, NOW()), (9, 2, NOW()),  -- Coffee for John and Jane
(10, 1, NOW()), (10, 2, NOW()), (10, 3, NOW()), -- Coffee for all three
(11, 1, NOW()), (11, 3, NOW()), -- Cappuccino for John and Bob
(12, 2, NOW()),                -- Cappuccino for Jane only
(13, 1, NOW()), (13, 2, NOW()), -- Croissant for John and Jane
(14, 3, NOW()), (14, 2, NOW()), -- Croissant for Bob and Jane
(15, 1, NOW()),                -- Muffin for John only
(16, 3, NOW());                -- Muffin for Bob only

-- Insert test payments
INSERT INTO payments (group_id, from_group_member_id, to_group_member_id, amount, currency, status, payment_method, notes, created_at, updated_at) VALUES
-- Roommates group payments
(1, 2, 1, 600.00, 'EUR', 'pending', 'bank_transfer', 'Rent payment', NOW(), NOW()),
(1, 3, 1, 75.00, 'EUR', 'completed', 'cash', 'Electricity payment', NOW(), NOW()),

-- Work team payments
(2, 2, 1, 28.50, 'EUR', 'pending', 'card', 'Lunch payment', NOW(), NOW()),
(2, 3, 1, 28.50, 'EUR', 'pending', 'card', 'Lunch payment', NOW(), NOW());

-- Display test data summary
SELECT 'Test Data Summary' as info;
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Groups', COUNT(*) FROM groups
UNION ALL
SELECT 'Group Members', COUNT(*) FROM group_members
UNION ALL
SELECT 'Expenses', COUNT(*) FROM expenses
UNION ALL
SELECT 'Items', COUNT(*) FROM items
UNION ALL
SELECT 'Assignments', COUNT(*) FROM assignments
UNION ALL
SELECT 'Payments', COUNT(*) FROM payments; 