-- database/seeds/seed_rooms.sql

-- Habitaciones Single (10 unidades)
INSERT INTO rooms (type, capacity, price_per_night, is_active)
SELECT 'single', 1, 800.00, true
FROM generate_series(1, 10);

-- Habitaciones Double (8 unidades)
INSERT INTO rooms (type, capacity, price_per_night, is_active)
SELECT 'double', 2, 1200.00, true
FROM generate_series(1, 8);

-- Suites (4 unidades)
INSERT INTO rooms (type, capacity, price_per_night, is_active)
SELECT 'suite', 3, 2500.00, true
FROM generate_series(1, 4);

-- Deluxe (2 unidades)
INSERT INTO rooms (type, capacity, price_per_night, is_active)
SELECT 'deluxe', 4, 4000.00, true
FROM generate_series(1, 2);

-- Inventario para los próximos 90 días
INSERT INTO room_inventory (room_type, date, total_count, available)
SELECT type, d::date, count, count
FROM (
    VALUES ('single', 10), ('double', 8), ('suite', 4), ('deluxe', 2)
) AS room_types(type, count)
CROSS JOIN generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', '1 day') AS d;
