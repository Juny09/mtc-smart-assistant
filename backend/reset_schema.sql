-- Reset Schema Script
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS carts CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP EXTENSION IF EXISTS vector CASCADE;

-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. User table (Users)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'staff')),
    full_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT REFERENCES categories(id)
);

-- 4. Products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    suggested_price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2), -- Protected field
    image_url TEXT,
    category_id INT REFERENCES categories(id),
    search_vector TSVECTOR,
    embedding VECTOR(1536), -- For AI embedding
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Carts
CREATE TABLE carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(100),
    user_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active',
    customer_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(id),
    product_id UUID REFERENCES products(id),
    quantity INT DEFAULT 1,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Audit Logs
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    target_resource VARCHAR(100),
    ip_address VARCHAR(45),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed initial Admin user (Password: Admin123!)
INSERT INTO users (username, password_hash, role, full_name)
VALUES ('admin', '$2a$11$U1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s', 'admin', 'System Administrator');
