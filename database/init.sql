CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL
);

CREATE TABLE bills (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  image_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE items (
  id SERIAL PRIMARY KEY,
  bill_id INTEGER REFERENCES bills(id),
  name VARCHAR(255),
  price NUMERIC
);

CREATE TABLE assignments (
  id SERIAL PRIMARY KEY,
  item_id INTEGER REFERENCES items(id),
  user_id INTEGER REFERENCES users(id)
); 