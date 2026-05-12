FROM postgres:15-alpine

COPY migrations/ /migrations/
COPY seeds/ /seeds/

ENTRYPOINT ["sh", "-c", "psql $DATABASE_URL -f /migrations/001_create_rooms.sql && psql $DATABASE_URL -f /migrations/002_create_guests.sql && psql $DATABASE_URL -f /migrations/003_create_reservations.sql && psql $DATABASE_URL -f /migrations/004_create_indexes.sql && psql $DATABASE_URL -f /seeds/seed_rooms.sql"]
