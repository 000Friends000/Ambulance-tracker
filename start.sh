#!/bin/sh

# Function to start a service if its JAR exists
start_service() {
    local jar_path="$1"
    local service_name="$2"
    local wait_time="$3"
    local port="$4"
    
    if [ -f "$jar_path" ]; then
        echo "Starting $service_name on port $port..."
        EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://localhost:8761/eureka/ \
        SERVER_PORT=$port \
        java -jar "$jar_path" &
        sleep "$wait_time"
    else
        echo "Warning: $service_name JAR not found at $jar_path"
    fi
}

echo "Starting services..."

# Start Eureka Server first
start_service "/app/eureka-server.jar" "Eureka Server" 60 8761

# Verify Eureka Server is up
echo "Waiting for Eureka Server to be ready..."
while ! curl -s http://localhost:8761/actuator/health > /dev/null; do
    echo "Waiting for Eureka Server..."
    sleep 5
done
echo "Eureka Server is ready!"

# Start API Gateway
start_service "/app/api-gateway.jar" "API Gateway" 30 8080

# Start other services
start_service "/app/ambulance-service.jar" "Ambulance Service" 15 8081
start_service "/app/hospital-service.jar" "Hospital Service" 15 8082
start_service "/app/route-optimization.jar" "Route Optimization Service" 15 8083

# Keep container running
wait
