# Use JRE for runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/eureka-server-0.0.1-SNAPSHOT.jar app.jar

# Expose the application port
EXPOSE 8761
ENTRYPOINT ["java", "-jar", "app.jar"]
