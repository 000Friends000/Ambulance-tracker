#!/bin/sh
set -e

# Create PostgreSQL data directory
mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Initialize PostgreSQL database
su postgres -c "initdb -D /var/lib/postgresql/data"

# Update PostgreSQL configuration to allow remote connections
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf

# Start PostgreSQL server
su postgres -c "pg_ctl -D /var/lib/postgresql/data start"

# Wait for PostgreSQL to start
sleep 5

# Create database and set up user
su postgres -c "createdb ambulance_db"
su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'root';\""

# Import initial schema if exists
if [ -f "/docker-entrypoint-initdb.d/init.sql" ]; then
    su postgres -c "psql -d ambulance_db -f /docker-entrypoint-initdb.d/init.sql"
fi

# Stop PostgreSQL server
su postgres -c "pg_ctl -D /var/lib/postgresql/data stop"
