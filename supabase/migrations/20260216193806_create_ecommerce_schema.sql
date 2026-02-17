/*
  # E-Commerce Database Schema

  1. New Tables
    - `categories`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `slug` (text, unique)
      - `description` (text)
      - `created_at` (timestamp)
    
    - `products`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `price` (numeric)
      - `image_url` (text)
      - `category_id` (uuid, foreign key)
      - `stock` (integer)
      - `featured` (boolean)
      - `created_at` (timestamp)
    
    - `cart_items`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `product_id` (uuid, foreign key)
      - `quantity` (integer)
      - `created_at` (timestamp)
    
    - `orders`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `total` (numeric)
      - `status` (text)
      - `customer_name` (text)
      - `customer_email` (text)
      - `customer_address` (text)
      - `created_at` (timestamp)
    
    - `order_items`
      - `id` (uuid, primary key)
      - `order_id` (uuid, foreign key)
      - `product_id` (uuid, foreign key)
      - `quantity` (integer)
      - `price` (numeric)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Categories and products are publicly readable
    - Cart items are private to authenticated users
    - Orders are private to authenticated users
    - Order items are accessible through orders
*/

CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  slug text UNIQUE NOT NULL,
  description text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  price numeric NOT NULL CHECK (price >= 0),
  image_url text DEFAULT '',
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  stock integer DEFAULT 0 CHECK (stock >= 0),
  featured boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  total numeric NOT NULL CHECK (total >= 0),
  status text DEFAULT 'pending',
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  customer_address text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric NOT NULL CHECK (price >= 0),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are publicly readable"
  ON categories FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Products are publicly readable"
  ON products FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view order items for own orders"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create order items for own orders"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

INSERT INTO categories (name, slug, description) VALUES
  ('Electronics', 'electronics', 'Latest gadgets and electronic devices'),
  ('Clothing', 'clothing', 'Fashion and apparel for everyone'),
  ('Home & Garden', 'home-garden', 'Everything for your home and garden'),
  ('Sports', 'sports', 'Sports equipment and outdoor gear')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, description, price, image_url, category_id, stock, featured) VALUES
  ('Wireless Headphones', 'Premium noise-cancelling wireless headphones with 30-hour battery life', 199.99, 'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg', (SELECT id FROM categories WHERE slug = 'electronics'), 50, true),
  ('Smart Watch', 'Fitness tracking smartwatch with heart rate monitor and GPS', 299.99, 'https://images.pexels.com/photos/437037/pexels-photo-437037.jpeg', (SELECT id FROM categories WHERE slug = 'electronics'), 30, true),
  ('Laptop Backpack', 'Durable laptop backpack with USB charging port', 49.99, 'https://images.pexels.com/photos/2905238/pexels-photo-2905238.jpeg', (SELECT id FROM categories WHERE slug = 'electronics'), 100, false),
  ('Running Shoes', 'Lightweight running shoes with superior cushioning', 89.99, 'https://images.pexels.com/photos/2529148/pexels-photo-2529148.jpeg', (SELECT id FROM categories WHERE slug = 'sports'), 75, true),
  ('Yoga Mat', 'Non-slip eco-friendly yoga mat with carrying strap', 34.99, 'https://images.pexels.com/photos/4056723/pexels-photo-4056723.jpeg', (SELECT id FROM categories WHERE slug = 'sports'), 120, false),
  ('Casual T-Shirt', 'Comfortable cotton t-shirt in various colors', 24.99, 'https://images.pexels.com/photos/1020585/pexels-photo-1020585.jpeg', (SELECT id FROM categories WHERE slug = 'clothing'), 200, false),
  ('Denim Jeans', 'Classic fit denim jeans for everyday wear', 59.99, 'https://images.pexels.com/photos/1598507/pexels-photo-1598507.jpeg', (SELECT id FROM categories WHERE slug = 'clothing'), 150, false),
  ('Coffee Maker', 'Programmable coffee maker with thermal carafe', 79.99, 'https://images.pexels.com/photos/324028/pexels-photo-324028.jpeg', (SELECT id FROM categories WHERE slug = 'home-garden'), 60, false),
  ('Indoor Plant Set', 'Collection of 3 low-maintenance indoor plants', 44.99, 'https://images.pexels.com/photos/4505166/pexels-photo-4505166.jpeg', (SELECT id FROM categories WHERE slug = 'home-garden'), 80, true),
  ('Desk Lamp', 'LED desk lamp with adjustable brightness and color temperature', 39.99, 'https://images.pexels.com/photos/1112598/pexels-photo-1112598.jpeg', (SELECT id FROM categories WHERE slug = 'home-garden'), 90, false)
ON CONFLICT DO NOTHING;