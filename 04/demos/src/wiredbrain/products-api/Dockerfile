FROM maven:3.6.3-jdk-11 AS builder

WORKDIR /usr/src/api
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY . .
RUN mvn package

# app
FROM openjdk:11-jre-slim

ENV LOG_LEVEL='DEBUG' \
    LOG_PATH='/app/logs' \
    INSTANCE_NAME='products-api-1'

WORKDIR ${LOG_PATH}
COPY logging.properties /app/config/logging/application.properties

WORKDIR /app
COPY --from=builder /usr/src/api/target/products-api-0.1.0.jar .

EXPOSE 80
ENTRYPOINT ["java", "-jar", "/app/products-api-0.1.0.jar"]