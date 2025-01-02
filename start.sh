#!/bin/sh

# Function to check if a port is available
check_port() {
    local port=$1
    if ! nc -z localhost $port; then
        return 0
    else
        return 1
    fi
}

# Function to start a service if its JAR exists
start_service() {
    local jar_path="$1"
    local service_name="$2"
    local wait_time="$3"
    local port="$4"
    
    if [ -f "$jar_path" ]; then
        echo "Starting $service_name on port $port..."
        
        # Check if port is available
        if ! check_port $port; then
            echo "Error: Port $port is already in use!"
            return 1
        fi
        
        # Start the service with environment variables
        EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://localhost:8761/eureka/ \
        SERVER_PORT=$port \
        java -jar "$jar_path" > /app/$service_name.log 2>&1 &
        
        local pid=$!
        echo "$service_name started with PID $pid"
        
        # Wait for the specified time
        echo "Waiting $wait_time seconds for $service_name to initialize..."
        sleep "$wait_time"
        
        # Check if process is still running
        if ! kill -0 $pid 2>/dev/null; then
            echo "Error: $service_name failed to start! Check logs at /app/$service_name.log"
            return 1
        fi
        
        echo "$service_name successfully started"
    else
        echo "Warning: $service_name JAR not found at $jar_path"
        return 1
    fi
}

echo "Starting services..."

# List all JARs in /app
echo "Available JARs:"
ls -la /app/*.jar || true

# Install netcat for port checking
apk add --no-cache netcat-openbsd

# Start Eureka Server first
start_service "/app/eureka-server.jar" "Eureka Server" 60 8761
if [ $? -ne 0 ]; then
    echo "Failed to start Eureka Server. Exiting..."
    exit 1
fi

# Verify Eureka Server is up
echo "Waiting for Eureka Server to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8761/actuator/health | grep -q "UP"; then
        echo "Eureka Server is ready!"
        break
    fi
    echo "Attempt $attempt/$max_attempts: Waiting for Eureka Server..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "Error: Eureka Server failed to start after $max_attempts attempts"
    echo "Eureka Server logs:"
    cat /app/Eureka\ Server.log
    exit 1
fi

# Start API Gateway
start_service "/app/api-gateway.jar" "API Gateway" 30 8080
if [ $? -ne 0 ]; then
    echo "Failed to start API Gateway. Exiting..."
    echo "API Gateway logs:"
    cat /app/API\ Gateway.log
    exit 1
fi

# Start other services
for service in \
    "/app/ambulance-service.jar:Ambulance Service:8081" \
    "/app/hospital-service.jar:Hospital Service:8082" \
    "/app/route-optimization-service.jar:Route Optimization Service:8083"; do
    
    IFS=: read jar name port <<EOF
$service
EOF
    
    start_service "$jar" "$name" 15 $port
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to start $name"
        echo "$name logs:"
        cat "/app/$name.log" || true
    fi
done

# Print status of all services
echo "\nService Status:"
echo "=============="
ps aux | grep java

# Keep container running and monitor logs
tail -f /app/*.log
