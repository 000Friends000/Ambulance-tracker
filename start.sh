#!/bin/sh

# Start Eureka Server and wait for it to be ready
java -jar /app/eureka-server.jar &
echo "Starting Eureka Server..."
sleep 45  # Increased wait time for Eureka Server

# Start API Gateway
java -jar /app/api-gateway.jar &
echo "Starting API Gateway..."
sleep 30  # Increased wait time for API Gateway

# Start other services
java -jar /app/ambulance-service.jar &
echo "Starting Ambulance Service..."
sleep 15

java -jar /app/hospital-service.jar &
echo "Starting Hospital Service..."
sleep 15

java -jar /app/route-optimization.jar &
echo "Starting Route Optimization Service..."

# Keep container running
wait
