# Use Maven to build the project
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Copy the source code
COPY . .
RUN mvn -B clean package -DskipTests

# Use JRE for runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar /app/app.jar

# Expose the application port
EXPOSE 8761
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
