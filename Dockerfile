# Build stage
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Copy all pom.xml files first for better caching
COPY pom.xml .
COPY eureka-server/pom.xml ./eureka-server/
COPY api-gateway/pom.xml ./api-gateway/
COPY Ambulance_Service/pom.xml ./Ambulance_Service/
COPY hospital-management-service/pom.xml ./hospital-management-service/
COPY route-optimization-service/pom.xml ./route-optimization-service/

# Copy source code
COPY . .

# Build all services
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Install curl for healthchecks
RUN apk add --no-cache curl

# Create app directory
WORKDIR /app

# Copy JARs from builder stage
COPY --from=builder /build /build

# Copy and run JAR files
RUN for jar in \
        /build/eureka-server/target/*.jar \
        /build/api-gateway/target/*.jar \
        /build/Ambulance_Service/target/*.jar \
        /build/hospital-management-service/target/*.jar \
        /build/route-optimization-service/target/*.jar; \
    do \
        if [ -e "$jar" ]; then \
            service_name=$(basename $(dirname $(dirname $jar))); \
            echo "Copying $jar to /app/$service_name.jar"; \
            cp "$jar" "/app/$service_name.jar"; \
        fi; \
    done && \
    rm -rf /build

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose ports
EXPOSE 8080 8761 8081 8082 8083 8084

# Start services using the startup script
ENTRYPOINT ["/app/start.sh"]
