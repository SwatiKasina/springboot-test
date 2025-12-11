# Gateway Service - Spring Boot Application

A Spring Boot microservice with CI/CD pipeline for building and deploying to AWS ECR.

## Overview

- **Application**: Spring Boot 4.0.0 with Java 17
- **Endpoints**: 
  - `/api/hello` - Sample endpoint with environment-specific messages
  - `/actuator/health` - Health check
  - `/actuator/prometheus` - Prometheus metrics
  - `/actuator/info` - Application info

## Project Structure

```
springboot-test/
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   ├── DemoApplication.java
│   │   │   └── controller/HelloController.java
│   │   └── resources/
│   │       ├── application.properties (base config)
│   │       ├── application-dev.properties (dev environment)
│   │       └── application-qa.properties (qa environment)
│   └── test/
│       └── java/com/example/demo/controller/HelloControllerTest.java
├── infra/
│   ├── pipeline.yaml (CI/CD pipeline)
│   └── tags.json (Resource tagging template)
├── Dockerfile (Alpine-based Docker image)
├── .dockerignore
└── pom.xml
```

## CI/CD Pipeline

### Pipeline Overview (`pipeline.yaml`)
Triggered by commits to `main` branch.

**Pipeline Stages:**
1. **Source** - Get code from GitHub
2. **ScanAndTest** - Vulnerability scan (Trivy) + Run Maven tests
3. **BuildJar** - Build JAR using version from pom.xml
4. **DockerAndECR** - Package JAR into Docker image and push to ECR

**How Versioning Works:**
- Version is read directly from `pom.xml` `<version>` tag
- Example: If pom.xml has `<version>0.0.1-SNAPSHOT</version>`, Docker image will be tagged as `0.0.1-SNAPSHOT`
- To release a new version: Update pom.xml version and push to main branch

**Parameters:**
- `Namespace` - Namespace for resource organization (e.g., `mycompany`, `dev`)
- `AppName` - Application name (default: `gateway-service`)
- `GitHubOwner` - GitHub organization/user
- `GitHubRepo` - Repository name
- `GitHubBranch` - Branch to monitor (default: `main`)
- `CodeStarConnectionArn` - ARN of AWS CodeStar connection

**Resources Created:**
- ECR Repository: `{Namespace}/{AppName}` (e.g., `mycompany/gateway-service`)
- S3 Bucket: `{Namespace}-{AppName}-artifacts-{Region}-{AccountId}`
- CodePipeline: `{Namespace}-{AppName}-Pipeline`
- CodeBuild Projects: 
  - `{Namespace}-{AppName}-ScanTest` (Vulnerability scanning & tests)
  - `{Namespace}-{AppName}-BuildJar` (JAR compilation)
  - `{Namespace}-{AppName}-Docker` (Docker image build & push)

**Tags Applied to All Resources:**
- `Namespace`: Resource namespace
- `AppName`: Application name
- `ManagedBy`: CloudFormation

**Docker Image Tags in ECR:**
- `{Namespace}/{AppName}:{version}` (e.g., `mycompany/gateway-service:0.0.1-SNAPSHOT`)
- `{Namespace}/{AppName}:latest`

## Local Development

### Prerequisites
- Java 17+
- Maven 3.6+
- Docker (optional, for local container testing)

### Build and Run

```bash
# Build the project
./mvnw clean install

# Run tests
./mvnw test

# Run with default profile
./mvnw spring-boot:run

# Run with dev profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Run with qa profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=qa
```

### Test Endpoints

```bash
# Hello endpoint
curl http://localhost:8080/api/hello

# Health check
curl http://localhost:8080/actuator/health

# Prometheus metrics
curl http://localhost:8080/actuator/prometheus

# Application info
curl http://localhost:8080/actuator/info
```

### Build Docker Image Locally

```bash
# First, build the JAR
./mvnw clean package -DskipTests

# Build Docker image
docker build -t gateway-service:local .

# Run container
docker run -p 8080:8080 gateway-service:local

# Run with dev profile
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=dev gateway-service:local
```

## AWS Deployment

### 1. Setup Prerequisites

**Create CodeStar Connection** (one-time setup):
1. Go to AWS Console → Developer Tools → Connections
2. Create connection to GitHub
3. Complete the authorization flow
4. Note the Connection ARN (e.g., `arn:aws:codestar-connections:us-east-1:123456789012:connection/abc-123`)

### 2. Deploy the Pipeline

```bash
aws cloudformation create-stack \
  --stack-name mycompany-gateway-service-pipeline \
  --template-body file://infra/pipeline.yaml \
  --parameters \
    ParameterKey=Namespace,ParameterValue=mycompany \
    ParameterKey=AppName,ParameterValue=gateway-service \
    ParameterKey=GitHubOwner,ParameterValue=YOUR_GITHUB_USER \
    ParameterKey=GitHubRepo,ParameterValue=YOUR_REPO_NAME \
    ParameterKey=CodeStarConnectionArn,ParameterValue=YOUR_CONNECTION_ARN \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 3. Monitor the Pipeline

After deployment:
1. Go to AWS Console → CodePipeline
2. Find your pipeline: `{Namespace}-{AppName}-Pipeline`
3. The pipeline will automatically trigger on the next commit to main branch

## Versioning & Release Strategy

### Updating Version
1. Update the `<version>` in `pom.xml`:
   ```xml
   <version>1.0.0</version>
   ```

2. Commit and push to main branch:
   ```bash
   git add pom.xml
   git commit -m "Bump version to 1.0.0"
   git push origin main
   ```

3. Pipeline automatically builds and pushes Docker image with version `1.0.0`

### Version Format
- **Development**: Use `-SNAPSHOT` suffix (e.g., `0.0.1-SNAPSHOT`)
- **Release**: Remove `-SNAPSHOT` (e.g., `1.0.0`)

## Environment-Specific Configuration

### DEV Environment
```properties
gateway.message=Hello World from DEV Environment!
gateway.environment=dev
logging.level.com.example.demo=DEBUG
```

### QA Environment
```properties
gateway.message=Hello World from QA Environment!
gateway.environment=qa
logging.level.com.example.demo=INFO
```

## Monitoring & Observability

- **Health Check**: `/actuator/health` - Application health status
- **Metrics**: `/actuator/prometheus` - Prometheus-format metrics
- **Info**: `/actuator/info` - Application version and build info

## Security Features

- **Vulnerability Scanning**: Trivy scanner runs on every build (HIGH & CRITICAL)
- **ECR Image Scanning**: Automatic scan on push enabled
- **Container Security**: Non-root user (spring:spring) in Docker image
- **Encryption**: KMS encryption for S3 artifacts
- **Least Privilege IAM**: Separate roles for Pipeline and CodeBuild

## Dockerfile Details

The Dockerfile uses a **single-stage** approach optimized for CI/CD:
- Base Image: `eclipse-temurin:17-jre-alpine` (lightweight Alpine Linux)
- Copies pre-built JAR from pipeline (no rebuild in Docker)
- Non-root user for security
- Health check using actuator endpoint
- JVM optimized for container environments

## Troubleshooting

### Build Failures
1. Check CodeBuild logs in CloudWatch: `/aws/codebuild/{Namespace}-{AppName}`
2. Verify Maven dependencies are accessible
3. Ensure tests pass locally: `./mvnw test`

### Docker Build Issues
1. Verify JAR exists in `target/` directory
2. Check Dockerfile syntax
3. Ensure ECR repository was created

### ECR Push Failures
1. Verify CodeBuild role has ECR permissions
2. Check ECR repository exists: `{Namespace}/{AppName}`
3. Verify AWS region matches

### Pipeline Not Triggering
1. Verify CodeStar connection is in "Available" state
2. Check GitHub webhook is configured
3. Ensure commits are to the monitored branch (default: main)

## Pipeline Architecture

```
GitHub (main branch)
    ↓
CodePipeline
    ↓
┌─────────────────────────────────────────┐
│  Stage 1: Source                        │
│  - Fetch code from GitHub               │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Stage 2: ScanAndTest                   │
│  - Install Trivy scanner                │
│  - Scan for vulnerabilities             │
│  - Run Maven tests                      │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Stage 3: BuildJar                      │
│  - Extract version from pom.xml         │
│  - Build JAR: mvnw clean package        │
│  - Save version for Docker stage        │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Stage 4: DockerAndECR                  │
│  - Copy pre-built JAR into image        │
│  - Build Alpine-based Docker image      │
│  - Tag: {version} and latest            │
│  - Push to ECR                          │
└─────────────────────────────────────────┘
    ↓
ECR: {Namespace}/{AppName}:{version}
     {Namespace}/{AppName}:latest
```

## Cost Optimization

- **ECR Lifecycle Policy**: Keeps only last 10 images (auto-cleanup)
- **S3 Versioning**: Enabled for audit trail
- **Log Retention**: CloudWatch logs retained for 7 days
- **Build Caching**: Maven dependencies cached between builds

## Next Steps

After deploying the pipeline:
1. ✅ Pipeline automatically triggers on commits to main
2. ✅ Update pom.xml version for releases
3. ⚠️ Set up deployment to EKS/ECS (separate infrastructure)
4. ⚠️ Configure monitoring and alerting
5. ⚠️ Set up multi-environment deployments (dev/qa/prod)

## License

[Your License Here]
