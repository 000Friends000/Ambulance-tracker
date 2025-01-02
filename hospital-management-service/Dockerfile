FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY hospital-management-service/pom.xml hospital-management-service/
RUN mvn -B -f hospital-management-service/pom.xml dependency:go-offline

COPY hospital-management-service/src hospital-management-service/src
RUN mvn -B -f hospital-management-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/hospital-management-service/target/*.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
