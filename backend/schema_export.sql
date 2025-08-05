-- CamSplit Database Schema Export
-- Generated on: 2025-08-01T21:49:25.430Z
-- Database: camsplit

-- =============================================
-- Table: assignment_users
-- =============================================
-- Many-to-many relationship between assignments and group members
CREATE TABLE assignment_users (
  assignment_id integer NOT NULL -- Reference to the assignment,
  group_member_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (assignment_id, group_member_id)
  ,CONSTRAINT assignment_users_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE
  ,CONSTRAINT assignment_users_group_member_id_fkey FOREIGN KEY (group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
);

-- Indexes for assignment_users
CREATE INDEX idx_assignment_users_assignment_id ON assignment_users (assignment_id);
CREATE INDEX idx_assignment_users_group_member_id ON assignment_users (group_member_id);

COMMENT ON TABLE assignment_users IS 'Many-to-many relationship between assignments and group members';

-- Column comments for assignment_users
COMMENT ON COLUMN assignment_users.assignment_id IS 'Reference to the assignment';

-- =============================================
-- Table: assignments
-- =============================================
-- Assignments of items to people with quantities and prices
CREATE TABLE assignments (
  id integer NOT NULL DEFAULT nextval('assignments_id_seq'::regclass),
  expense_id integer,
  item_id integer,
  quantity numeric NOT NULL DEFAULT 1 -- Quantity assigned in this assignment (cannot exceed item max_quantity),
  unit_price numeric NOT NULL,
  total_price numeric NOT NULL,
  people_count integer NOT NULL DEFAULT 1 -- Number of people sharing this assignment,
  price_per_person numeric NOT NULL -- Price per person (manually set by frontend to avoid precision issues),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT assignments_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
  ,CONSTRAINT assignments_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- Indexes for assignments
CREATE INDEX idx_assignments_expense_id ON assignments (expense_id);
CREATE INDEX idx_assignments_item_id ON assignments (item_id);

COMMENT ON TABLE assignments IS 'Assignments of items to people with quantities and prices';

-- Column comments for assignments
COMMENT ON COLUMN assignments.quantity IS 'Quantity assigned in this assignment (cannot exceed item max_quantity)';
COMMENT ON COLUMN assignments.people_count IS 'Number of people sharing this assignment';
COMMENT ON COLUMN assignments.price_per_person IS 'Price per person (manually set by frontend to avoid precision issues)';

-- =============================================
-- Table: expense_payers
-- =============================================
-- Who paid for each expense (supports multiple payers)
CREATE TABLE expense_payers (
  id integer NOT NULL DEFAULT nextval('expense_payers_id_seq'::regclass),
  expense_id integer,
  group_member_id integer,
  amount_paid numeric NOT NULL,
  payment_method character varying(50) DEFAULT 'unknown'::character varying,
  payment_date timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT expense_payers_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
  ,CONSTRAINT expense_payers_group_member_id_fkey FOREIGN KEY (group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
);

-- Indexes for expense_payers
CREATE INDEX idx_expense_payers_expense_id ON expense_payers (expense_id);
CREATE INDEX idx_expense_payers_group_member_id ON expense_payers (group_member_id);

COMMENT ON TABLE expense_payers IS 'Who paid for each expense (supports multiple payers)';

-- =============================================
-- Table: expense_splits
-- =============================================
-- How each expense is split among group members
CREATE TABLE expense_splits (
  id integer NOT NULL DEFAULT nextval('expense_splits_id_seq'::regclass),
  expense_id integer,
  group_member_id integer,
  amount_owed numeric NOT NULL,
  split_type character varying(20) DEFAULT 'equal'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  percentage numeric -- Percentage value for percentage-based splits (0-100). NULL for equal and custom splits.
  ,PRIMARY KEY (id)
  ,CONSTRAINT expense_splits_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
  ,CONSTRAINT expense_splits_group_member_id_fkey FOREIGN KEY (group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
);

-- Indexes for expense_splits
CREATE INDEX idx_expense_splits_expense_id ON expense_splits (expense_id);
CREATE INDEX idx_expense_splits_group_member_id ON expense_splits (group_member_id);
CREATE INDEX idx_expense_splits_percentage ON expense_splits (percentage);

COMMENT ON TABLE expense_splits IS 'How each expense is split among group members';

-- Column comments for expense_splits
COMMENT ON COLUMN expense_splits.percentage IS 'Percentage value for percentage-based splits (0-100). NULL for equal and custom splits.';

-- =============================================
-- Table: expenses
-- =============================================
-- Expenses created within groups
CREATE TABLE expenses (
  id integer NOT NULL DEFAULT nextval('expenses_id_seq'::regclass),
  title character varying(255) NOT NULL,
  total_amount numeric NOT NULL,
  currency character varying(3) DEFAULT 'EUR'::character varying,
  date date NOT NULL,
  category character varying(100) DEFAULT 'Other'::character varying,
  notes text,
  group_id integer,
  split_type character varying(20) DEFAULT 'equal'::character varying,
  receipt_image_url character varying(500),
  created_by integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT expenses_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
  ,CONSTRAINT expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for expenses
CREATE INDEX idx_expenses_created_by ON expenses (created_by);
CREATE INDEX idx_expenses_date ON expenses (date);
CREATE INDEX idx_expenses_group_id ON expenses (group_id);

COMMENT ON TABLE expenses IS 'Expenses created within groups';

-- =============================================
-- Table: group_members
-- =============================================
-- Members of groups, can be registered users or non-users
CREATE TABLE group_members (
  id integer NOT NULL DEFAULT nextval('group_members_id_seq'::regclass),
  group_id integer,
  user_id integer,
  nickname character varying(255) NOT NULL,
  email character varying(255),
  role character varying(50) DEFAULT 'member'::character varying,
  is_registered_user boolean DEFAULT false,
  joined_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT group_members_group_id_nickname_key UNIQUE (group_id, nickname)
  ,CONSTRAINT group_members_group_id_user_id_key UNIQUE (group_id, user_id)
  ,CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
  ,CONSTRAINT group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes for group_members
CREATE UNIQUE INDEX group_members_group_id_nickname_key ON group_members (nickname, group_id);
CREATE UNIQUE INDEX group_members_group_id_user_id_key ON group_members (group_id, user_id);
CREATE INDEX idx_group_members_email ON group_members (email);
CREATE INDEX idx_group_members_group_id ON group_members (group_id);
CREATE INDEX idx_group_members_nickname ON group_members (nickname);
CREATE INDEX idx_group_members_user_id ON group_members (user_id);

COMMENT ON TABLE group_members IS 'Members of groups, can be registered users or non-users';

-- =============================================
-- Table: groups
-- =============================================
-- Groups that users can create and join for expense sharing
CREATE TABLE groups (
  id integer NOT NULL DEFAULT nextval('groups_id_seq'::regclass),
  name character varying(255) NOT NULL,
  description text,
  image_url character varying(500),
  created_by integer,
  currency character varying(3) DEFAULT 'EUR'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for groups
CREATE INDEX idx_groups_created_by ON groups (created_by);

COMMENT ON TABLE groups IS 'Groups that users can create and join for expense sharing';

-- =============================================
-- Table: group_invites
-- =============================================
-- Invite links for joining groups
CREATE TABLE group_invites (
  id integer NOT NULL DEFAULT nextval('group_invites_id_seq'::regclass),
  group_id integer NOT NULL,
  invite_code character varying(255) UNIQUE NOT NULL,
  created_by integer NOT NULL,
  expires_at timestamp with time zone,
  max_uses integer DEFAULT 1,
  current_uses integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT group_invites_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
  ,CONSTRAINT group_invites_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Indexes for group_invites
CREATE INDEX idx_group_invites_group_id ON group_invites (group_id);
CREATE INDEX idx_group_invites_invite_code ON group_invites (invite_code);
CREATE INDEX idx_group_invites_created_by ON group_invites (created_by);
CREATE INDEX idx_group_invites_expires_at ON group_invites (expires_at);
CREATE INDEX idx_group_invites_is_active ON group_invites (is_active);

COMMENT ON TABLE group_invites IS 'Invite links for joining groups';

-- =============================================
-- Table: items
-- =============================================
-- Individual items from receipts that can be assigned to people
CREATE TABLE items (
  id integer NOT NULL DEFAULT nextval('items_id_seq'::regclass),
  expense_id integer,
  name character varying(255) NOT NULL,
  description text,
  unit_price numeric NOT NULL,
  max_quantity integer NOT NULL DEFAULT 1 -- Maximum quantity available for this item (from receipt),
  total_price numeric NOT NULL -- Total price for all available quantity (unit_price * max_quantity),
  category character varying(100) DEFAULT 'Other'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT items_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
);

-- Indexes for items
CREATE INDEX idx_items_expense_id ON items (expense_id);
CREATE INDEX idx_items_name ON items (name);

COMMENT ON TABLE items IS 'Individual items from receipts that can be assigned to people';

-- Column comments for items
COMMENT ON COLUMN items.max_quantity IS 'Maximum quantity available for this item (from receipt)';
COMMENT ON COLUMN items.total_price IS 'Total price for all available quantity (unit_price * max_quantity)';

-- =============================================
-- Table: payments
-- =============================================
-- Payments between group members for settling debts
CREATE TABLE payments (
  id integer NOT NULL DEFAULT nextval('payments_id_seq'::regclass),
  group_id integer,
  from_group_member_id integer,
  to_group_member_id integer,
  amount numeric NOT NULL,
  currency character varying(3) DEFAULT 'EUR'::character varying,
  status character varying(20) DEFAULT 'pending'::character varying,
  payment_method character varying(50),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT payments_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
  ,CONSTRAINT payments_from_group_member_id_fkey FOREIGN KEY (from_group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
  ,CONSTRAINT payments_to_group_member_id_fkey FOREIGN KEY (to_group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
);

-- Indexes for payments
CREATE INDEX idx_payments_from_group_member ON payments (from_group_member_id);
CREATE INDEX idx_payments_group_id ON payments (group_id);
CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_to_group_member ON payments (to_group_member_id);

COMMENT ON TABLE payments IS 'Payments between group members for settling debts';

-- =============================================
-- Table: receipt_images
-- =============================================
-- Receipt images uploaded for OCR processing
CREATE TABLE receipt_images (
  id integer NOT NULL DEFAULT nextval('receipt_images_id_seq'::regclass),
  expense_id integer,
  image_url character varying(500) NOT NULL,
  ocr_data jsonb,
  created_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT receipt_images_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
);

-- Indexes for receipt_images

COMMENT ON TABLE receipt_images IS 'Receipt images uploaded for OCR processing';

-- =============================================
-- Table: settlements
-- =============================================
-- Optimal debt settlements calculated for groups to minimize transactions
CREATE TABLE settlements (
  id integer NOT NULL DEFAULT nextval('settlements_id_seq'::regclass),
  group_id integer -- Reference to the group this settlement belongs to,
  from_group_member_id integer -- Group member who owes money (debtor),
  to_group_member_id integer -- Group member who should receive money (creditor),
  amount numeric NOT NULL -- Amount to be settled,
  currency character varying(3) DEFAULT 'EUR'::character varying -- Currency code (3-letter ISO),
  status character varying(20) DEFAULT 'active'::character varying -- Settlement status: active, settled, or obsolete,
  calculation_timestamp timestamp with time zone DEFAULT now() -- When this settlement was calculated,
  settled_at timestamp with time zone -- When this settlement was marked as settled,
  settled_by integer -- User who marked this settlement as settled,
  created_expense_id integer -- Expense created when settlement was marked as settled,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT settlements_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
  ,CONSTRAINT settlements_from_group_member_id_fkey FOREIGN KEY (from_group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
  ,CONSTRAINT settlements_to_group_member_id_fkey FOREIGN KEY (to_group_member_id) REFERENCES group_members(id) ON DELETE CASCADE
  ,CONSTRAINT settlements_settled_by_fkey FOREIGN KEY (settled_by) REFERENCES users(id)
  ,CONSTRAINT settlements_created_expense_id_fkey FOREIGN KEY (created_expense_id) REFERENCES expenses(id)
);

-- Indexes for settlements
CREATE INDEX idx_settlements_active_by_group ON settlements (group_id);
CREATE INDEX idx_settlements_calculation_timestamp ON settlements (calculation_timestamp);
CREATE INDEX idx_settlements_created_expense ON settlements (created_expense_id);
CREATE INDEX idx_settlements_from_member ON settlements (from_group_member_id);
CREATE INDEX idx_settlements_group_id ON settlements (group_id);
CREATE INDEX idx_settlements_group_status ON settlements (group_id, status);
CREATE INDEX idx_settlements_settled_by ON settlements (settled_by);
CREATE INDEX idx_settlements_status ON settlements (status);
CREATE INDEX idx_settlements_to_member ON settlements (to_group_member_id);

COMMENT ON TABLE settlements IS 'Optimal debt settlements calculated for groups to minimize transactions';

-- Column comments for settlements
COMMENT ON COLUMN settlements.group_id IS 'Reference to the group this settlement belongs to';
COMMENT ON COLUMN settlements.from_group_member_id IS 'Group member who owes money (debtor)';
COMMENT ON COLUMN settlements.to_group_member_id IS 'Group member who should receive money (creditor)';
COMMENT ON COLUMN settlements.amount IS 'Amount to be settled';
COMMENT ON COLUMN settlements.currency IS 'Currency code (3-letter ISO)';
COMMENT ON COLUMN settlements.status IS 'Settlement status: active, settled, or obsolete';
COMMENT ON COLUMN settlements.calculation_timestamp IS 'When this settlement was calculated';
COMMENT ON COLUMN settlements.settled_at IS 'When this settlement was marked as settled';
COMMENT ON COLUMN settlements.settled_by IS 'User who marked this settlement as settled';
COMMENT ON COLUMN settlements.created_expense_id IS 'Expense created when settlement was marked as settled';

-- =============================================
-- Table: user_preferences
-- =============================================
-- User application preferences and settings
CREATE TABLE user_preferences (
  id integer NOT NULL DEFAULT nextval('user_preferences_id_seq'::regclass),
  user_id integer,
  currency character varying(3) DEFAULT 'USD'::character varying,
  language character varying(10) DEFAULT 'en'::character varying,
  notifications boolean DEFAULT true,
  email_notifications boolean DEFAULT true,
  dark_mode boolean DEFAULT false,
  biometric_auth boolean DEFAULT false,
  auto_sync boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
  ,PRIMARY KEY (id)
  ,CONSTRAINT user_preferences_user_id_key UNIQUE (user_id)
  ,CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for user_preferences
CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id);
CREATE UNIQUE INDEX user_preferences_user_id_key ON user_preferences (user_id);

COMMENT ON TABLE user_preferences IS 'User application preferences and settings';

-- =============================================
-- Table: users
-- =============================================
-- User accounts for the application
CREATE TABLE users (
  id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  email character varying(255) NOT NULL,
  password character varying(255) NOT NULL,
  birthdate date,
  avatar character varying(500),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  first_name character varying(255) -- User first name,
  last_name character varying(255) -- User last name,
  phone character varying(20) -- User phone number,
  bio text -- User biography/description,
  is_email_verified boolean DEFAULT false -- Whether user email is verified,
  timezone character varying(50) DEFAULT 'UTC'::character varying -- User timezone preference
  ,PRIMARY KEY (id)
  ,CONSTRAINT users_email_key UNIQUE (email)
);

-- Indexes for users
CREATE INDEX idx_users_email_verified ON users (is_email_verified);
CREATE INDEX idx_users_phone ON users (phone);
CREATE UNIQUE INDEX users_email_key ON users (email);

COMMENT ON TABLE users IS 'User accounts for the application';

-- Column comments for users
COMMENT ON COLUMN users.first_name IS 'User first name';
COMMENT ON COLUMN users.last_name IS 'User last name';
COMMENT ON COLUMN users.phone IS 'User phone number';
COMMENT ON COLUMN users.bio IS 'User biography/description';
COMMENT ON COLUMN users.is_email_verified IS 'Whether user email is verified';
COMMENT ON COLUMN users.timezone IS 'User timezone preference';

-- =============================================
-- Sequences
-- =============================================
-- Sequence: assignments_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: expense_payers_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: expense_splits_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: expenses_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: group_invites_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: group_members_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: groups_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: items_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: payments_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: receipt_images_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: settlements_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: user_preferences_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

-- Sequence: users_id_seq
-- Data type: integer
-- Start value: 1
-- Increment: 1
-- Min value: 1
-- Max value: 2147483647

