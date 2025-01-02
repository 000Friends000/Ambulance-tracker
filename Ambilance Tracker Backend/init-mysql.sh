#!/bin/sh
set -e

# Create MySQL directories with proper permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# Initialize MySQL data directory
mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Start MySQL server
mysqld --user=mysql --datadir=/var/lib/mysql &

# Wait for MySQL to start
sleep 10

# Create database and set root password
mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ambulance_db;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Import initial schema if exists
if [ -f "/docker-entrypoint-initdb.d/init.sql" ]; then
    mysql -u root -proot ambulance_db < /docker-entrypoint-initdb.d/init.sql
fi

# Stop MySQL server gracefully
mysqladmin -u root -proot shutdown
