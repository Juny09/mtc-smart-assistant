-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. User table (Users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'staff')),
    full_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Categories
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INT REFERENCES categories(id)
);

-- 4. Products
CREATE TABLE IF NOT EXISTS products (
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
CREATE TABLE IF NOT EXISTS carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(100),
    user_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active',
    customer_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(id),
    product_id UUID REFERENCES products(id),
    quantity INT DEFAULT 1,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    target_resource VARCHAR(100),
    ip_address VARCHAR(45),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed initial Admin user (Password: Admin123!)
-- Note: In production, use a proper hash. This is a placeholder for the MVP setup.
INSERT INTO users (username, password_hash, role, full_name)
VALUES ('admin', '$2a$11$U1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s1.s.s', 'admin', 'System Administrator')
ON CONFLICT (username) DO NOTHING;
