# Use Maven to build the project
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Copy pom.xml and download dependencies
COPY pom.xml .
COPY eureka-server/pom.xml eureka-server/
RUN mvn -B -f eureka-server/pom.xml dependency:go-offline

# Copy the source code
COPY eureka-server/src eureka-server/src
RUN mvn -B -f eureka-server/pom.xml clean package -DskipTests

# Use JRE for runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/eureka-server/target/*.jar app.jar

# Expose the application port
EXPOSE 8761
ENTRYPOINT ["java", "-jar", "app.jar"]
