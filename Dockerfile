FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

WORKDIR /app

# Create a non-root user
RUN useradd -r -u 1000 spring

COPY target/gateway-service-*.jar app.jar

# Give ownership to the non-root user
RUN chown spring:spring app.jar

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
