-- USERS
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  birthdate DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- BILLS
CREATE TABLE bills (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  image_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ITEMS
CREATE TABLE items (
  id SERIAL PRIMARY KEY,
  bill_id INTEGER REFERENCES bills(id),
  name VARCHAR(255),
  unit_price NUMERIC, --
  total_price NUMERIC, --
  quantity INTEGER DEFAULT 1,
  quantity_left INTEGER DEFAULT 1 --
);



-- PARTICIPANTS
CREATE TABLE participants (
  id SERIAL PRIMARY KEY,
  bill_id INTEGER REFERENCES bills(id),
  name VARCHAR(255) NOT NULL,
  user_id INTEGER REFERENCES users(id),
  amount_paid NUMERIC DEFAULT 0, --
  amount_owed NUMERIC DEFAULT 0 --
);

-- ASSIGNMENTS
CREATE TABLE assignments (
  id SERIAL PRIMARY KEY,
  bill_id INTEGER REFERENCES bills(id),
  item_id INTEGER REFERENCES items(id),
  participant_id INTEGER REFERENCES participants(id),
  quantity INTEGER DEFAULT 1,
  cost_per_person NUMERIC
);
CREATE UNIQUE INDEX assignments_unique ON assignments (bill_id, item_id, participant_id);

-- PAYMENTS
CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  bill_id INTEGER REFERENCES bills(id),
  from_participant_id INTEGER REFERENCES participants(id),
  to_participant_id INTEGER REFERENCES participants(id),
  amount NUMERIC NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE --
); 

