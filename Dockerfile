# Production image for Google Cloud Run (Java 21).
# Build stage uses the same Gradle version as the wrapper (8.10.2).
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /workspace
COPY . .
RUN ./gradlew :apps:api:bootJar --no-daemon

# Runtime stage: minimal JRE, non-root user (Cloud Run best practice).
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --create-home --uid 61000 appuser
USER appuser
# Cloud Run passes the listening port via PORT; keep heap within container memory.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
COPY --from=build /workspace/apps/api/build/libs/api-0.0.1-SNAPSHOT.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
