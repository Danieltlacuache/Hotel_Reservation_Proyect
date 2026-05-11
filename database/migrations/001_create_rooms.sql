-- database/migrations/001_create_rooms.sql

CREATE TABLE rooms (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type        VARCHAR(20) NOT NULL CHECK (type IN ('single', 'double', 'suite', 'deluxe')),
    capacity    INTEGER NOT NULL CHECK (capacity > 0),
    price_per_night DECIMAL(10, 2) NOT NULL CHECK (price_per_night > 0),
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE rooms IS 'Catálogo de habitaciones del hotel';
