-- database/migrations/003_create_reservations.sql

CREATE TYPE reservation_status AS ENUM ('Pendiente', 'Confirmada', 'Cancelada', 'Completada');

CREATE TABLE reservations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id     UUID NOT NULL REFERENCES rooms(id),
    guest_id    UUID NOT NULL REFERENCES guests(id),
    room_type   VARCHAR(20) NOT NULL CHECK (room_type IN ('single', 'double', 'suite', 'deluxe')),
    check_in    DATE NOT NULL,
    check_out   DATE NOT NULL,
    status      reservation_status NOT NULL DEFAULT 'Pendiente',
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_dates CHECK (check_out > check_in)
);

COMMENT ON TABLE reservations IS 'Reservaciones con ciclo de vida: Pendiente → Confirmada → Completada/Cancelada';
