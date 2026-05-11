-- database/migrations/004_create_indexes.sql

-- Tabla de inventario por tipo de habitación y fecha
CREATE TABLE room_inventory (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_type   VARCHAR(20) NOT NULL CHECK (room_type IN ('single', 'double', 'suite', 'deluxe')),
    date        DATE NOT NULL,
    total_count INTEGER NOT NULL CHECK (total_count >= 0),
    available   INTEGER NOT NULL CHECK (available >= 0),
    CONSTRAINT uq_inventory UNIQUE (room_type, date),
    CONSTRAINT chk_available CHECK (available <= total_count)
);

COMMENT ON TABLE room_inventory IS 'Inventario de habitaciones por tipo y fecha — fuente de verdad durable';

-- Índices para consultas frecuentes
CREATE INDEX idx_reservations_status ON reservations (status);
CREATE INDEX idx_reservations_dates ON reservations (check_in, check_out);
CREATE INDEX idx_reservations_room ON reservations (room_id);
CREATE INDEX idx_reservations_guest ON reservations (guest_id);
CREATE INDEX idx_inventory_type_date ON room_inventory (room_type, date);
