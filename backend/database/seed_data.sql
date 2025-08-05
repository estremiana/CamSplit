-- Seed Data for CamSplit Backend
-- Description: Sample data for testing the new database schema
-- Date: 2024-01-01
-- Author: CamSplit Team

-- Clear existing data (if any)
TRUNCATE TABLE receipt_images, payments, expense_splits, expense_payers, expenses, group_members, groups, users RESTART IDENTITY CASCADE;

-- Insert sample users
INSERT INTO users (email, password, name, birthdate, avatar, created_at, updated_at) VALUES
('john.doe@example.com', '$2b$10$rQZ8K9vX2mN3pL4qR5sT6u', 'John Doe', '1990-05-15', 'https://ui-avatars.com/api/?name=John+Doe&background=4F46E5&color=fff', NOW(), NOW()),
('jane.smith@example.com', '$2b$10$sRZ9L0wY3nO4qM5rS6tU7v', 'Jane Smith', '1992-08-22', 'https://ui-avatars.com/api/?name=Jane+Smith&background=059669&color=fff', NOW(), NOW()),
('bob.wilson@example.com', '$2b$10$tSZ0M1xZ4oP5rN6sT7uV8w', 'Bob Wilson', '1988-12-10', 'https://ui-avatars.com/api/?name=Bob+Wilson&background=DC2626&color=fff', NOW(), NOW()),
('alice.johnson@example.com', '$2b$10$uTA1N2yA5pQ6sO7tU8vW9x', 'Alice Johnson', '1995-03-28', 'https://ui-avatars.com/api/?name=Alice+Johnson&background=7C3AED&color=fff', NOW(), NOW());

-- Insert sample groups
INSERT INTO groups (name, description, image_url, created_by, currency, created_at, updated_at) VALUES
('Roommates', 'Monthly apartment expenses and utilities', NULL, 1, 'EUR', NOW(), NOW()),
('Weekend Getaway', 'Trip to the mountains with friends', NULL, 2, 'EUR', NOW(), NOW()),
('Office Lunch', 'Daily lunch expenses with colleagues', NULL, 3, 'EUR', NOW(), NOW());

-- Insert group members
INSERT INTO group_members (group_id, user_id, nickname, email, role, is_registered_user, joined_at) VALUES
-- Roommates group
(1, 1, 'John', 'john.doe@example.com', 'admin', true, NOW()),
(1, 2, 'Jane', 'jane.smith@example.com', 'member', true, NOW()),
(1, NULL, 'Roommate Bob', 'bob.roommate@example.com', 'member', false, NOW()),
(1, NULL, 'Roommate Alice', 'alice.roommate@example.com', 'member', false, NOW()),

-- Weekend Getaway group
(2, 2, 'Jane', 'jane.smith@example.com', 'admin', true, NOW()),
(2, 1, 'John', 'john.doe@example.com', 'member', true, NOW()),
(2, 3, 'Bob', 'bob.wilson@example.com', 'member', true, NOW()),
(2, 4, 'Alice', 'alice.johnson@example.com', 'member', true, NOW()),

-- Office Lunch group
(3, 3, 'Bob', 'bob.wilson@example.com', 'admin', true, NOW()),
(3, 4, 'Alice', 'alice.johnson@example.com', 'member', true, NOW()),
(3, NULL, 'Colleague Mike', 'mike.colleague@example.com', 'member', false, NOW());

-- Insert sample expenses
INSERT INTO expenses (title, total_amount, currency, date, category, notes, group_id, split_type, receipt_image_url, created_by, created_at, updated_at) VALUES
-- Roommates expenses
('Rent Payment', 1200.00, 'EUR', '2024-01-01', 'Housing', 'Monthly rent payment', 1, 'equal', NULL, 1, NOW(), NOW()),
('Electricity Bill', 85.50, 'EUR', '2024-01-15', 'Utilities', 'January electricity bill', 1, 'equal', NULL, 2, NOW(), NOW()),
('Grocery Shopping', 156.78, 'EUR', '2024-01-20', 'Food', 'Weekly groceries', 1, 'custom', NULL, 1, NOW(), NOW()),

-- Weekend Getaway expenses
('Hotel Booking', 400.00, 'EUR', '2024-01-10', 'Accommodation', 'Weekend hotel stay', 2, 'equal', NULL, 2, NOW(), NOW()),
('Restaurant Dinner', 120.00, 'EUR', '2024-01-11', 'Food', 'Group dinner at local restaurant', 2, 'equal', NULL, 3, NOW(), NOW()),

-- Office Lunch expenses
('Team Lunch', 45.00, 'EUR', '2024-01-22', 'Food', 'Team lunch at cafeteria', 3, 'equal', NULL, 3, NOW(), NOW());

-- Insert expense payers (multiple payers for some expenses)
INSERT INTO expense_payers (expense_id, group_member_id, amount_paid, payment_method, payment_date, created_at) VALUES
-- Rent Payment (split between John and Jane)
(1, 1, 800.00, 'bank_transfer', NOW(), NOW()),
(1, 2, 400.00, 'bank_transfer', NOW(), NOW()),

-- Electricity Bill (paid by Jane)
(2, 2, 85.50, 'card', NOW(), NOW()),

-- Grocery Shopping (paid by John)
(3, 1, 156.78, 'card', NOW(), NOW()),

-- Hotel Booking (paid by Jane)
(4, 2, 400.00, 'card', NOW(), NOW()),

-- Restaurant Dinner (paid by Bob)
(5, 3, 120.00, 'card', NOW(), NOW()),

-- Team Lunch (paid by Bob)
(6, 3, 45.00, 'cash', NOW(), NOW());

-- Insert expense splits
INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type, created_at) VALUES
-- Rent Payment (split equally among 4 roommates)
(1, 1, 300.00, 'equal', NOW()),
(1, 2, 300.00, 'equal', NOW()),
(1, 3, 300.00, 'equal', NOW()),
(1, 4, 300.00, 'equal', NOW()),

-- Electricity Bill (split equally among 4 roommates)
(2, 1, 21.38, 'equal', NOW()),
(2, 2, 21.38, 'equal', NOW()),
(2, 3, 21.38, 'equal', NOW()),
(2, 4, 21.38, 'equal', NOW()),

-- Grocery Shopping (custom split)
(3, 1, 50.00, 'custom', NOW()),
(3, 2, 40.00, 'custom', NOW()),
(3, 3, 35.00, 'custom', NOW()),
(3, 4, 31.78, 'custom', NOW()),

-- Hotel Booking (split equally among 4 friends)
(4, 2, 100.00, 'equal', NOW()),
(4, 1, 100.00, 'equal', NOW()),
(4, 3, 100.00, 'equal', NOW()),
(4, 4, 100.00, 'equal', NOW()),

-- Restaurant Dinner (split equally among 4 friends)
(5, 2, 30.00, 'equal', NOW()),
(5, 1, 30.00, 'equal', NOW()),
(5, 3, 30.00, 'equal', NOW()),
(5, 4, 30.00, 'equal', NOW()),

-- Team Lunch (split equally among 3 colleagues)
(6, 3, 15.00, 'equal', NOW()),
(6, 4, 15.00, 'equal', NOW()),
(6, 5, 15.00, 'equal', NOW());

-- Insert sample payments (settlements)
INSERT INTO payments (group_id, from_group_member_id, to_group_member_id, amount, currency, status, payment_method, notes, created_at, updated_at) VALUES
-- Roommates settlements
(1, 3, 1, 256.16, 'EUR', 'pending', 'bank_transfer', 'Settlement for rent and utilities', NOW(), NOW()),
(1, 4, 1, 252.94, 'EUR', 'pending', 'bank_transfer', 'Settlement for rent and utilities', NOW(), NOW()),
(1, 3, 2, 64.12, 'EUR', 'completed', 'cash', 'Settlement for electricity', NOW(), NOW()),

-- Weekend Getaway settlements
(2, 1, 2, 130.00, 'EUR', 'pending', 'bank_transfer', 'Settlement for hotel and dinner', NOW(), NOW()),
(2, 3, 2, 130.00, 'EUR', 'pending', 'bank_transfer', 'Settlement for hotel and dinner', NOW(), NOW()),
(2, 4, 2, 130.00, 'EUR', 'pending', 'bank_transfer', 'Settlement for hotel and dinner', NOW(), NOW()),

-- Office Lunch settlements
(3, 4, 3, 15.00, 'EUR', 'completed', 'cash', 'Settlement for team lunch', NOW(), NOW()),
(3, 5, 3, 15.00, 'EUR', 'pending', 'cash', 'Settlement for team lunch', NOW(), NOW());

-- Insert sample receipt images
INSERT INTO receipt_images (expense_id, image_url, ocr_data, created_at) VALUES
(3, 'https://example.com/receipts/grocery-receipt.jpg', '{"total": 156.78, "items": [{"name": "Milk", "price": 2.50}, {"name": "Bread", "price": 1.20}]}', NOW()),
(5, 'https://example.com/receipts/restaurant-receipt.jpg', '{"total": 120.00, "items": [{"name": "Pizza", "price": 25.00}, {"name": "Wine", "price": 35.00}]}', NOW());

-- Display summary of inserted data
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Groups', COUNT(*) FROM groups
UNION ALL
SELECT 'Group Members', COUNT(*) FROM group_members
UNION ALL
SELECT 'Expenses', COUNT(*) FROM expenses
UNION ALL
SELECT 'Expense Payers', COUNT(*) FROM expense_payers
UNION ALL
SELECT 'Expense Splits', COUNT(*) FROM expense_splits
UNION ALL
SELECT 'Payments', COUNT(*) FROM payments
UNION ALL
SELECT 'Receipt Images', COUNT(*) FROM receipt_images
ORDER BY table_name; 