# CamSplit Database Documentation

## Overview

The CamSplit database is designed to manage expense sharing and settlements between group members. It supports multiple split types (equal, custom, percentage), item-level assignments, and automated settlement calculations.

**Database Name:** `camsplit`  
**Last Updated:** 2025-08-01T21:49:25.430Z

## Table Structure

### Core Tables

#### 1. `users` - User Accounts
**Purpose:** Stores user account information and authentication data.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `email` | varchar(255) | NO | - | Unique email address |
| `password_hash` | varchar(255) | NO | - | Hashed password |
| `first_name` | varchar(100) | NO | - | User's first name |
| `last_name` | varchar(100) | NO | - | User's last name |
| `phone` | varchar(20) | YES | - | Phone number |
| `avatar` | varchar(500) | YES | - | Profile picture URL |
| `is_email_verified` | boolean | YES | false | Email verification status |
| `created_at` | timestamp | YES | now() | Account creation time |
| `updated_at` | timestamp | YES | now() | Last update time |

**Indexes:**
- `users_email_key` (UNIQUE) - Email uniqueness
- `idx_users_email_verified` - Email verification status
- `idx_users_phone` - Phone number lookups

#### 2. `groups` - Expense Groups
**Purpose:** Defines groups where users can share expenses.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `name` | varchar(255) | NO | - | Group name |
| `description` | text | YES | - | Group description |
| `image_url` | varchar(500) | YES | - | Group image URL |
| `created_by` | integer | YES | - | User who created the group |
| `currency` | varchar(3) | YES | 'EUR' | Default currency |
| `created_at` | timestamp | YES | now() | Group creation time |
| `updated_at` | timestamp | YES | now() | Last update time |

**Foreign Keys:**
- `created_by` → `users(id)`

**Indexes:**
- `idx_groups_created_by` - Group creator lookups

#### 3. `group_members` - Group Membership
**Purpose:** Manages user membership in groups with roles and nicknames.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `group_id` | integer | NO | - | Reference to group |
| `user_id` | integer | YES | - | Reference to user (NULL for unregistered) |
| `nickname` | varchar(100) | NO | - | Display name in group |
| `email` | varchar(255) | YES | - | Email for unregistered users |
| `role` | varchar(20) | YES | 'member' | Role: 'admin', 'member' |
| `is_registered_user` | boolean | YES | false | Whether user has account |
| `joined_at` | timestamp | YES | now() | Join timestamp |

**Foreign Keys:**
- `group_id` → `groups(id)` ON DELETE CASCADE
- `user_id` → `users(id)` ON DELETE CASCADE

**Unique Constraints:**
- `(nickname, group_id)` - Unique nicknames per group
- `(group_id, user_id)` - One membership per user per group

**Indexes:**
- `idx_group_members_group_id` - Group membership lookups
- `idx_group_members_user_id` - User membership lookups
- `idx_group_members_nickname` - Nickname lookups
- `idx_group_members_email` - Email lookups

### Expense Management Tables

#### 4. `expenses` - Main Expense Records
**Purpose:** Stores expense information including amounts, categories, and split types.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `title` | varchar(255) | NO | - | Expense title |
| `total_amount` | numeric(10,2) | NO | - | Total expense amount |
| `currency` | varchar(3) | YES | 'EUR' | Currency code |
| `date` | date | NO | - | Expense date |
| `category` | varchar(100) | YES | 'Other' | Expense category |
| `notes` | text | YES | - | Additional notes |
| `group_id` | integer | YES | - | Reference to group |
| `split_type` | varchar(20) | YES | 'equal' | Split type: 'equal', 'custom', 'percentage' |
| `receipt_image_url` | varchar(500) | YES | - | Receipt image URL |
| `created_by` | integer | YES | - | User who created expense |
| `created_at` | timestamp | YES | now() | Creation timestamp |
| `updated_at` | timestamp | YES | now() | Last update timestamp |

**Foreign Keys:**
- `group_id` → `groups(id)` ON DELETE CASCADE
- `created_by` → `users(id)`

**Indexes:**
- `idx_expenses_group_id` - Group expense lookups
- `idx_expenses_created_by` - Creator lookups
- `idx_expenses_date` - Date-based queries

#### 5. `expense_payers` - Who Paid for Expenses
**Purpose:** Tracks who actually paid for each expense (supports multiple payers).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `expense_id` | integer | YES | - | Reference to expense |
| `group_member_id` | integer | YES | - | Reference to group member |
| `amount_paid` | numeric | NO | - | Amount paid by this member |
| `payment_method` | varchar(50) | YES | 'unknown' | Payment method used |
| `payment_date` | timestamp | YES | now() | When payment was made |
| `created_at` | timestamp | YES | now() | Record creation time |

**Foreign Keys:**
- `expense_id` → `expenses(id)` ON DELETE CASCADE
- `group_member_id` → `group_members(id)` ON DELETE CASCADE

**Indexes:**
- `idx_expense_payers_expense_id` - Expense payer lookups
- `idx_expense_payers_group_member_id` - Member payment lookups

#### 6. `expense_splits` - How Expenses Are Split
**Purpose:** Defines how each expense is divided among group members.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `expense_id` | integer | YES | - | Reference to expense |
| `group_member_id` | integer | YES | - | Reference to group member |
| `amount_owed` | numeric | NO | - | Amount owed by this member |
| `split_type` | varchar(20) | YES | 'equal' | Split type: 'equal', 'custom', 'percentage' |
| `percentage` | numeric | YES | - | Percentage for percentage splits (0-100) |
| `created_at` | timestamp | YES | now() | Record creation time |

**Foreign Keys:**
- `expense_id` → `expenses(id)` ON DELETE CASCADE
- `group_member_id` → `group_members(id)` ON DELETE CASCADE

**Indexes:**
- `idx_expense_splits_expense_id` - Expense split lookups
- `idx_expense_splits_group_member_id` - Member split lookups
- `idx_expense_splits_percentage` - Percentage-based queries

### Item-Level Management Tables

#### 7. `items` - Individual Items in Expenses
**Purpose:** Stores individual items within expenses for detailed tracking.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `expense_id` | integer | YES | - | Reference to expense |
| `name` | varchar(255) | NO | - | Item name |
| `price` | numeric | NO | - | Item price |
| `quantity` | integer | YES | 1 | Item quantity |
| `max_quantity` | integer | YES | - | Maximum assignable quantity |
| `created_at` | timestamp | YES | now() | Creation timestamp |

**Foreign Keys:**
- `expense_id` → `expenses(id)` ON DELETE CASCADE

**Indexes:**
- `idx_items_expense_id` - Expense item lookups
- `idx_items_name` - Item name searches

#### 8. `assignments` - Item Assignments to People
**Purpose:** Tracks which items are assigned to which people with quantities and prices.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `expense_id` | integer | YES | - | Reference to expense |
| `item_id` | integer | YES | - | Reference to item |
| `quantity` | numeric | NO | 1 | Quantity assigned |
| `unit_price` | numeric | NO | - | Price per unit |
| `total_price` | numeric | NO | - | Total price for this assignment |
| `people_count` | integer | NO | 1 | Number of people sharing |
| `price_per_person` | numeric | NO | - | Price per person |
| `notes` | text | YES | - | Assignment notes |
| `created_at` | timestamp | YES | now() | Creation timestamp |
| `updated_at` | timestamp | YES | now() | Last update timestamp |

**Foreign Keys:**
- `expense_id` → `expenses(id)` ON DELETE CASCADE
- `item_id` → `items(id)` ON DELETE CASCADE

**Indexes:**
- `idx_assignments_expense_id` - Expense assignment lookups
- `idx_assignments_item_id` - Item assignment lookups

#### 9. `assignment_users` - Assignment to Member Mapping
**Purpose:** Many-to-many relationship between assignments and group members.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `assignment_id` | integer | NO | - | Reference to assignment |
| `group_member_id` | integer | NO | - | Reference to group member |
| `created_at` | timestamp | YES | now() | Creation timestamp |

**Primary Key:** `(assignment_id, group_member_id)`

**Foreign Keys:**
- `assignment_id` → `assignments(id)` ON DELETE CASCADE
- `group_member_id` → `group_members(id)` ON DELETE CASCADE

**Indexes:**
- `idx_assignment_users_assignment_id` - Assignment lookups
- `idx_assignment_users_group_member_id` - Member assignment lookups

### Settlement and Payment Tables

#### 10. `settlements` - Calculated Settlements
**Purpose:** Stores calculated settlements between group members.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `group_id` | integer | NO | - | Reference to group |
| `from_group_member_id` | integer | NO | - | Member who owes money |
| `to_group_member_id` | integer | NO | - | Member who is owed money |
| `amount` | numeric | NO | - | Settlement amount |
| `currency` | varchar(3) | YES | 'EUR' | Currency |
| `status` | varchar(20) | YES | 'active' | Status: 'active', 'settled', 'obsolete' |
| `calculation_timestamp` | timestamp | YES | - | When settlement was calculated |
| `settled_at` | timestamp | YES | - | When settlement was completed |
| `settled_by` | integer | YES | - | User who marked as settled |
| `created_expense_id` | integer | YES | - | Expense created for settlement |
| `created_at` | timestamp | YES | now() | Creation timestamp |
| `updated_at` | timestamp | YES | now() | Last update timestamp |

**Foreign Keys:**
- `group_id` → `groups(id)` ON DELETE CASCADE
- `from_group_member_id` → `group_members(id)` ON DELETE CASCADE
- `to_group_member_id` → `group_members(id)` ON DELETE CASCADE
- `settled_by` → `users(id)`
- `created_expense_id` → `expenses(id)`

**Indexes:**
- `idx_settlements_group_id` - Group settlement lookups
- `idx_settlements_from_member` - Debtor lookups
- `idx_settlements_to_member` - Creditor lookups
- `idx_settlements_status` - Status-based queries
- `idx_settlements_group_status` - Group and status queries
- `idx_settlements_calculation_timestamp` - Calculation time queries
- `idx_settlements_active_by_group` - Active settlements by group
- `idx_settlements_settled_by` - Settled by user queries
- `idx_settlements_created_expense` - Settlement expense lookups

#### 11. `payments` - Payment Records
**Purpose:** Tracks actual payments made between members.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `group_id` | integer | NO | - | Reference to group |
| `from_group_member_id` | integer | NO | - | Member who paid |
| `to_group_member_id` | integer | NO | - | Member who received |
| `amount` | numeric | NO | - | Payment amount |
| `currency` | varchar(3) | YES | 'EUR' | Currency |
| `status` | varchar(20) | YES | 'pending' | Status: 'pending', 'completed', 'cancelled' |
| `payment_method` | varchar(50) | YES | - | Payment method used |
| `notes` | text | YES | - | Payment notes |
| `created_at` | timestamp | YES | now() | Creation timestamp |
| `updated_at` | timestamp | YES | now() | Last update timestamp |

**Foreign Keys:**
- `group_id` → `groups(id)` ON DELETE CASCADE
- `from_group_member_id` → `group_members(id)` ON DELETE CASCADE
- `to_group_member_id` → `group_members(id)` ON DELETE CASCADE

**Indexes:**
- `idx_payments_group_id` - Group payment lookups
- `idx_payments_from_group_member` - Payer lookups
- `idx_payments_to_group_member` - Payee lookups
- `idx_payments_status` - Status-based queries

### Supporting Tables

#### 12. `receipt_images` - Receipt Storage
**Purpose:** Stores receipt images for expenses.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `expense_id` | integer | NO | - | Reference to expense |
| `image_url` | varchar(500) | NO | - | Image URL |
| `file_name` | varchar(255) | YES | - | Original filename |
| `file_size` | integer | YES | - | File size in bytes |
| `mime_type` | varchar(100) | YES | - | MIME type |
| `uploaded_at` | timestamp | YES | now() | Upload timestamp |

**Foreign Keys:**
- `expense_id` → `expenses(id)` ON DELETE CASCADE

#### 13. `user_preferences` - User Settings
**Purpose:** Stores user preferences and settings.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | integer | NO | auto-increment | Primary key |
| `user_id` | integer | NO | - | Reference to user |
| `default_currency` | varchar(3) | YES | 'EUR' | Default currency |
| `language` | varchar(10) | YES | 'en' | Language preference |
| `timezone` | varchar(50) | YES | 'UTC' | Timezone preference |
| `notifications_enabled` | boolean | YES | true | Notification settings |
| `created_at` | timestamp | YES | now() | Creation timestamp |
| `updated_at` | timestamp | YES | now() | Last update timestamp |

**Foreign Keys:**
- `user_id` → `users(id)` ON DELETE CASCADE

**Unique Constraints:**
- `user_id` - One preference record per user

**Indexes:**
- `idx_user_preferences_user_id` - User preference lookups
- `user_preferences_user_id_key` (UNIQUE) - User uniqueness

## Key Relationships

### Core Relationships
1. **Users → Groups** (via `group_members`)
   - Users can belong to multiple groups
   - Each membership has a role and nickname

2. **Groups → Expenses**
   - Each expense belongs to one group
   - Expenses are deleted when group is deleted (CASCADE)

3. **Expenses → Splits & Payers**
   - Each expense has multiple splits (how it's divided)
   - Each expense has multiple payers (who actually paid)

### Item-Level Relationships
1. **Expenses → Items**
   - Each expense can have multiple items
   - Items are deleted when expense is deleted (CASCADE)

2. **Items → Assignments**
   - Each item can have multiple assignments
   - Assignments track quantities and prices

3. **Assignments → Group Members** (via `assignment_users`)
   - Many-to-many relationship
   - Tracks which members are assigned to which items

### Settlement Relationships
1. **Groups → Settlements**
   - Each group can have multiple settlements
   - Settlements are calculated based on expense splits

2. **Settlements → Payments**
   - Settlements can be resolved through payments
   - Payments track actual money transfers

## Split Types

The system supports three split types:

1. **Equal** (`split_type = 'equal'`)
   - Amount is divided equally among selected members
   - `percentage` field is NULL

2. **Custom** (`split_type = 'custom'`)
   - Each member has a specific amount assigned
   - `percentage` field is NULL
   - `amount_owed` contains the custom amount

3. **Percentage** (`split_type = 'percentage'`)
   - Amount is divided based on percentages
   - `percentage` field contains the percentage (0-100)
   - `amount_owed` contains the calculated amount

## Important Notes

### Cascade Deletions
- When a group is deleted, all related data is deleted (expenses, members, settlements, etc.)
- When an expense is deleted, all related data is deleted (splits, payers, items, assignments, etc.)
- When a user is deleted, their memberships and preferences are deleted

### Data Integrity
- Group member nicknames must be unique within a group
- Users can only have one membership per group
- Email addresses must be unique across all users
- Settlement amounts are calculated automatically based on expense splits

### Performance Considerations
- Indexes are created on frequently queried columns
- Foreign key relationships ensure data integrity
- Unique constraints prevent duplicate data

## Common Queries

### Get Group Balances
```sql
SELECT 
  gm.id as member_id,
  gm.nickname,
  COALESCE(SUM(ep.amount_paid), 0) as total_paid,
  COALESCE(SUM(es.amount_owed), 0) as total_owed,
  (COALESCE(SUM(ep.amount_paid), 0) - COALESCE(SUM(es.amount_owed), 0)) as balance
FROM group_members gm
LEFT JOIN expense_payers ep ON gm.id = ep.group_member_id
LEFT JOIN expense_splits es ON gm.id = es.group_member_id
WHERE gm.group_id = $1
GROUP BY gm.id, gm.nickname;
```

### Get Expense with Details
```sql
SELECT 
  e.*,
  json_agg(DISTINCT jsonb_build_object(
    'id', ep.id,
    'group_member_id', ep.group_member_id,
    'amount_paid', ep.amount_paid,
    'payment_method', ep.payment_method
  )) as payers,
  json_agg(DISTINCT jsonb_build_object(
    'id', es.id,
    'group_member_id', es.group_member_id,
    'amount_owed', es.amount_owed,
    'split_type', es.split_type,
    'percentage', es.percentage
  )) as splits
FROM expenses e
LEFT JOIN expense_payers ep ON e.id = ep.expense_id
LEFT JOIN expense_splits es ON e.id = es.expense_id
WHERE e.id = $1
GROUP BY e.id;
```

### Get Active Settlements
```sql
SELECT 
  s.*,
  from_member.nickname as from_nickname,
  to_member.nickname as to_nickname
FROM settlements s
JOIN group_members from_member ON s.from_group_member_id = from_member.id
JOIN group_members to_member ON s.to_group_member_id = to_member.id
WHERE s.group_id = $1 AND s.status = 'active'
ORDER BY s.amount DESC;
``` 