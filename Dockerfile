# Dockerfile for Spring Boot application with Alpine Linux
# Expects pre-built JAR from CI/CD pipeline

FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023
WORKDIR /app

# Install curl for healthcheck (Amazon Linux 2023 uses dnf, not apk)
RUN dnf install -y curl shadow-utils \
    && dnf clean all

# Create non-root user for security (Amazon Linux 2023 base image)
RUN groupadd -r spring && useradd -r -g spring spring

# Copy the pre-built JAR from pipeline
COPY target/gateway-service-*.jar app.jar

# Change ownership to spring user
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring:spring

# Expose port
EXPOSE 8080

# Health check using curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Set JVM options optimized for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
