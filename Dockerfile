FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

WORKDIR /app

# Copy the pre-built JAR from the pipeline
COPY target/gateway-service-*.jar app.jar

# Expose application port
EXPOSE 8080

# Run the application (using the default user from the base image)
ENTRYPOINT ["java", "-jar", "app.jar"]
