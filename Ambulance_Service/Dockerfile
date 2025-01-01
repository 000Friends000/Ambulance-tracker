FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY Ambulance_Service/pom.xml Ambulance_Service/
RUN mvn -B -f Ambulance_Service/pom.xml dependency:go-offline

COPY Ambulance_Service/src Ambulance_Service/src
RUN mvn -B -f Ambulance_Service/pom.xml clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/Ambulance_Service/target/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
