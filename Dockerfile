FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy JAR files from builder stage
COPY --from=builder /build/eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar /app/eureka-server.jar
COPY --from=builder /build/Ambulance_Service/target/Ambulance_Service-0.0.1-SNAPSHOT.jar /app/ambulance-service.jar
COPY --from=builder /build/hospital-management-service/target/hospital-management-service-0.0.1-SNAPSHOT.jar /app/hospital-service.jar
COPY --from=builder /build/route-optimization-service/target/route-optimization-service-0.0.1-SNAPSHOT.jar /app/route-optimization.jar

# Copy the startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8761 8081 8083 8084

CMD ["/app/start.sh"]
