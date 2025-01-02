FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY route-optimization-service/pom.xml route-optimization-service/
RUN mvn -B -f route-optimization-service/pom.xml dependency:go-offline

COPY route-optimization-service/src route-optimization-service/src
RUN mvn -B -f route-optimization-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/route-optimization-service/target/*.jar app.jar
EXPOSE 8084
ENTRYPOINT ["java", "-jar", "app.jar"]
