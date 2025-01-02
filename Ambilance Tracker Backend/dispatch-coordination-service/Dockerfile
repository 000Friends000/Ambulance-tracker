FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY dispatch-coordination-service/pom.xml dispatch-coordination-service/
RUN mvn -B -f dispatch-coordination-service/pom.xml dependency:go-offline

COPY dispatch-coordination-service/src dispatch-coordination-service/src
RUN mvn -B -f dispatch-coordination-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/dispatch-coordination-service/target/*.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
