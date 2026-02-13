-- Seed Products
INSERT INTO categories (name) VALUES ('Water Pump'), ('Generator'), ('Air Compressor');

INSERT INTO products (code, name, description, suggested_price, cost_price, category_id, image_url)
VALUES 
('WP-2024-X', 'High Pressure Water Pump 2HP', 'Suitable for agricultural irrigation, 50m head. High durability.', 250.00, 150.00, 1, 'https://placehold.co/400x300/png?text=Water+Pump'),
('GEN-5KW-D', 'Diesel Generator 5KW', 'Silent type, suitable for home backup. 10 hours runtime.', 1200.00, 850.00, 2, 'https://placehold.co/400x300/png?text=Generator'),
('AC-50L', 'Air Compressor 50L', '2HP Motor, 8 Bar max pressure. Good for painting.', 180.00, 110.00, 3, 'https://placehold.co/400x300/png?text=Compressor'),
('CM-MIXER-1', 'Cement Mixer 1 Bag', 'Portable electric cement mixer. Easy to clean.', 350.00, 220.00, 1, 'https://placehold.co/400x300/png?text=Mixer')
ON CONFLICT (code) DO NOTHING;
