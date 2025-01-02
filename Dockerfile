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

# Copy and run JAR files with fixed naming
RUN for jar in \
        /build/eureka-server/target/*.jar \
        /build/api-gateway/target/*.jar \
        /build/Ambulance_Service/target/*.jar \
        /build/hospital-management-service/target/*.jar \
        /build/route-optimization-service/target/*.jar; \
    do \
        if [ -e "$jar" ]; then \
            case $(basename $(dirname $(dirname $jar))) in \
                "eureka-server") cp "$jar" "/app/eureka-server.jar" ;;
                "api-gateway") cp "$jar" "/app/api-gateway.jar" ;;
                "Ambulance_Service") cp "$jar" "/app/ambulance-service.jar" ;;
                "hospital-management-service") cp "$jar" "/app/hospital-service.jar" ;;
                "route-optimization-service") cp "$jar" "/app/route-optimization-service.jar" ;;
            esac \
        fi \
    done && \
    ls -la /app/*.jar && \
    rm -rf /build

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose ports
EXPOSE 8080 8761 8081 8082 8083 8084

# Start services using the startup script
ENTRYPOINT ["/app/start.sh"]
