-- Create database if not exists
CREATE DATABASE IF NOT EXISTS ambulance_db;
USE ambulance_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON ambulance_db.* TO 'root'@'%' IDENTIFIED BY 'root';
FLUSH PRIVILEGES;
