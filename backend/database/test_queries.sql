-- Test Queries for CamSplit Database
-- Run these queries to verify the database schema and relationships

-- 1. Test basic table structure
SELECT 'Testing table structure...' as info;

-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'groups', 'group_members', 'expenses', 'expense_payers', 'expense_splits', 'payments', 'receipt_images')
ORDER BY table_name;

-- 2. Test user data
SELECT 'Testing user data...' as info;
SELECT id, name, email, created_at FROM users ORDER BY id;

-- 3. Test group data
SELECT 'Testing group data...' as info;
SELECT g.id, g.name, g.description, u.name as created_by, g.currency, g.created_at
FROM groups g
JOIN users u ON g.created_by = u.id
ORDER BY g.id;

-- 4. Test group members (including non-users)
SELECT 'Testing group members...' as info;
SELECT 
  gm.id,
  g.name as group_name,
  gm.nickname,
  gm.email,
  gm.role,
  gm.is_registered_user,
  u.name as user_name,
  gm.joined_at
FROM group_members gm
JOIN groups g ON gm.group_id = g.id
LEFT JOIN users u ON gm.user_id = u.id
ORDER BY g.id, gm.id;

-- 5. Test expenses with group info
SELECT 'Testing expenses...' as info;
SELECT 
  e.id,
  e.title,
  e.total_amount,
  e.currency,
  e.category,
  e.split_type,
  g.name as group_name,
  u.name as created_by,
  e.date,
  e.created_at
FROM expenses e
JOIN groups g ON e.group_id = g.id
JOIN users u ON e.created_by = u.id
ORDER BY e.id;

-- 6. Test expense payers (multiple payers)
SELECT 'Testing expense payers...' as info;
SELECT 
  ep.id,
  e.title as expense_title,
  gm.nickname as payer_name,
  ep.amount_paid,
  ep.payment_method,
  ep.payment_date
FROM expense_payers ep
JOIN expenses e ON ep.expense_id = e.id
JOIN group_members gm ON ep.group_member_id = gm.id
ORDER BY e.id, ep.id;

-- 7. Test expense splits
SELECT 'Testing expense splits...' as info;
SELECT 
  es.id,
  e.title as expense_title,
  gm.nickname as member_name,
  es.amount_owed,
  es.split_type
FROM expense_splits es
JOIN expenses e ON es.expense_id = e.id
JOIN group_members gm ON es.group_member_id = gm.id
ORDER BY e.id, es.id;

-- 8. Test payments
SELECT 'Testing payments...' as info;
SELECT 
  p.id,
  g.name as group_name,
  from_member.nickname as from_member,
  to_member.nickname as to_member,
  p.amount,
  p.currency,
  p.status,
  p.payment_method,
  p.created_at
FROM payments p
JOIN groups g ON p.group_id = g.id
JOIN group_members from_member ON p.from_group_member_id = from_member.id
JOIN group_members to_member ON p.to_group_member_id = to_member.id
ORDER BY p.id;

-- 9. Test receipt images
SELECT 'Testing receipt images...' as info;
SELECT 
  ri.id,
  e.title as expense_title,
  ri.image_url,
  ri.ocr_data,
  ri.created_at
FROM receipt_images ri
JOIN expenses e ON ri.expense_id = e.id
ORDER BY ri.id;

-- 10. Test complex relationships - Group with all expenses and members
SELECT 'Testing complex relationships...' as info;
SELECT 
  g.id as group_id,
  g.name as group_name,
  COUNT(DISTINCT gm.id) as member_count,
  COUNT(DISTINCT e.id) as expense_count,
  COALESCE(SUM(e.total_amount), 0) as total_expenses,
  g.currency
FROM groups g
LEFT JOIN group_members gm ON g.id = gm.group_id
LEFT JOIN expenses e ON g.id = e.group_id
GROUP BY g.id, g.name, g.currency
ORDER BY g.id;

-- 11. Test member balances (amount paid vs amount owed)
SELECT 'Testing member balances...' as info;
SELECT 
  g.name as group_name,
  gm.nickname as member_name,
  COALESCE(SUM(ep.amount_paid), 0) as total_paid,
  COALESCE(SUM(es.amount_owed), 0) as total_owed,
  COALESCE(SUM(ep.amount_paid), 0) - COALESCE(SUM(es.amount_owed), 0) as balance
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
LEFT JOIN expense_payers ep ON gm.id = ep.group_member_id
LEFT JOIN expense_splits es ON gm.id = es.group_member_id
GROUP BY g.id, g.name, gm.id, gm.nickname
ORDER BY g.id, gm.id;

-- 12. Test foreign key constraints
SELECT 'Testing foreign key constraints...' as info;

-- Check for orphaned records
SELECT 'Orphaned expense_payers:' as check_type, COUNT(*) as count
FROM expense_payers ep
LEFT JOIN expenses e ON ep.expense_id = e.id
WHERE e.id IS NULL

UNION ALL

SELECT 'Orphaned expense_splits:' as check_type, COUNT(*) as count
FROM expense_splits es
LEFT JOIN expenses e ON es.expense_id = e.id
WHERE e.id IS NULL

UNION ALL

SELECT 'Orphaned payments:' as check_type, COUNT(*) as count
FROM payments p
LEFT JOIN groups g ON p.group_id = g.id
WHERE g.id IS NULL;

-- 13. Test data integrity - Total paid should equal total owed for each expense
SELECT 'Testing expense balance integrity...' as info;
SELECT 
  e.id,
  e.title,
  e.total_amount,
  COALESCE(SUM(ep.amount_paid), 0) as total_paid,
  COALESCE(SUM(es.amount_owed), 0) as total_owed,
  CASE 
    WHEN COALESCE(SUM(ep.amount_paid), 0) = COALESCE(SUM(es.amount_owed), 0) THEN 'BALANCED'
    ELSE 'UNBALANCED'
  END as status
FROM expenses e
LEFT JOIN expense_payers ep ON e.id = ep.expense_id
LEFT JOIN expense_splits es ON e.id = es.expense_id
GROUP BY e.id, e.title, e.total_amount
ORDER BY e.id;

-- 14. Performance test - Index usage
SELECT 'Testing index performance...' as info;
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
  e.title,
  e.total_amount,
  gm.nickname as payer_name,
  ep.amount_paid
FROM expenses e
JOIN expense_payers ep ON e.id = ep.expense_id
JOIN group_members gm ON ep.group_member_id = gm.id
WHERE e.group_id = 1
ORDER BY e.created_at DESC
LIMIT 10; 