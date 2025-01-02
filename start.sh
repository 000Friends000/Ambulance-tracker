#!/bin/sh

# Function to start a service if its JAR exists
start_service() {
    local jar_path="$1"
    local service_name="$2"
    local wait_time="$3"
    
    if [ -f "$jar_path" ]; then
        echo "Starting $service_name..."
        java -jar "$jar_path" &
        sleep "$wait_time"
    else
        echo "Warning: $service_name JAR not found at $jar_path"
    fi
}

# Start Eureka Server first
start_service "/app/eureka-server.jar" "Eureka Server" 45

# Start API Gateway
start_service "/app/api-gateway.jar" "API Gateway" 30

# Start other services
start_service "/app/ambulance-service.jar" "Ambulance Service" 15
start_service "/app/hospital-service.jar" "Hospital Service" 15
start_service "/app/route-optimization.jar" "Route Optimization Service" 15

# Keep container running
wait
