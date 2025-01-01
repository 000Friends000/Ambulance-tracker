FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY api-gateway/pom.xml api-gateway/
RUN mvn -B -f api-gateway/pom.xml dependency:go-offline

COPY api-gateway/src api-gateway/src
RUN mvn -B -f api-gateway/pom.xml clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/api-gateway/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
