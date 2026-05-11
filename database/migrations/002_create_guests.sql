-- database/migrations/002_create_guests.sql

CREATE TABLE guests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(200) NOT NULL,
    email       VARCHAR(254) NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_guests_email ON guests (email);

COMMENT ON TABLE guests IS 'Datos de huéspedes registrados';
