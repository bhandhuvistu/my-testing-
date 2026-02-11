# My Testing App - CI/CD Pipeline

Complete DevOps and CI/CD pipeline demonstration using Docker, Kubernetes, Jenkins, and SonarQube.

## 📋 Project Structure

```
my-testing-app/
├── .jenkins/                          # Jenkins pipeline files
│   ├── scm_demo
│   ├── parallel-executions
│   ├── parameterized-builds
│   ├── sonarqube-analysis
│   ├── sonar-status-check
│   ├── github-push-trigger
│   ├── function-demo
│   ├── jenkins-pipeline-9am-sep-2018
│   └── nov-2018-7am-devops
├── helm/node-app/                     # Kubernetes Helm charts
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   └── templates/
├── src/                               # Application source code
│   └── main/
│       ├── java/com/example/
│       │   └── HelloServlet.java
│       └── webapp/
│           ├── index.html
│           └── WEB-INF/web.xml
├── Dockerfile                         # Multi-stage Docker build (Java 17)
├── Dockerfile.tomcat                  # Tomcat 10.x with Java 17
├── tomcat-config.sh                   # Tomcat configuration
├── pom.xml                            # Maven configuration (Java 17)
├── Jenkinsfile                        # Main CI/CD pipeline
├── deploy-to-tomcat
├── deploy-to-tomcat-java17.sh         # Optimized Tomcat deployer
├── deploy-war-to-tomcat
├── deploy-env                         # Multi-environment deployer
└── README.md
```

## 🚀 Features

- **Maven**: Java project building
- **Docker**: Multi-stage container builds
- **Kubernetes/Helm**: Production deployments
- **Jenkins**: Complete CI/CD pipelines
- **SonarQube**: Code quality analysis
- **Multi-environment**: Dev, Staging, Production support

## 📦 Prerequisites

- Docker & Docker Compose
- Kubernetes cluster (minikube, EKS, AKS)
- Helm 3.x
- Jenkins 2.x
- Maven 3.8.x
- Java 17+
- Tomcat 10.x (optional)
- SonarQube Server

## 🔧 Quick Start

### 1. Build Application
```bash
mvn clean package
```

### 2. Build Docker Image
```bash
docker build -t my-testing-app:1.0.0 .
```

### 3. Deploy to Kubernetes
```bash
kubectl create namespace production
helm install my-app ./helm/node-app -n production
```

### 4. Verify Deployment
```bash
kubectl get deployments -n production
kubectl get pods -n production
```

### 5. Deploy to Tomcat (Java 17)
```bash
# Configure Tomcat path (if not at /opt/tomcat)
export TOMCAT_HOME=/path/to/tomcat

# Deploy application
./deploy-to-tomcat-java17.sh

# Access application
curl http://localhost:8080/my-app
```

### 6. Deploy Tomcat Docker Container
```bash
docker build -f Dockerfile.tomcat -t my-testing-app-tomcat:1.0.0 .
docker run -p 8080:8080 my-testing-app-tomcat:1.0.0
```

## 🌍 Multi-Environment Deployment

```bash
# Development
./deploy-env dev 1.0.0

# Staging
./deploy-env staging 1.0.0

# Production
./deploy-env prod 1.0.0
```

## 📝 Pipeline Stages (Main Jenkinsfile)

1. **Checkout** - Clone git repository
2. **Build** - Compile with Maven
3. **Test** - Run unit tests
4. **SonarQube** - Code quality analysis
5. **Docker Build** - Create container image
6. **Push** - Upload to Docker registry
7. **Deploy** - Deploy to Kubernetes using Helm

## 🐱 Tomcat Deployment (Java 17)

### Quick Tomcat Setup
```bash
# Using the optimized deployment script
./deploy-to-tomcat-java17.sh

# The script will:
# 1. Verify Java 17 installation
# 2. Build the WAR file automatically
# 3. Stop Tomcat gracefully
# 4. Backup existing deployment
# 5. Deploy new WAR
# 6. Perform health checks
# 7. Rollback on failure
```

### Docker Tomcat Build
```bash
# Build Tomcat container with Java 17
docker build -f Dockerfile.tomcat -t my-testing-app-tomcat:1.0 .

# Run container
docker run -d -p 8080:8080 --name app-tomcat my-testing-app-tomcat:1.0

# View logs
docker logs -f app-tomcat

# Access app
curl http://localhost:8080/my-app
```

### Configuration
Edit `tomcat-config.sh` to customize:
- `TOMCAT_HOME` - Tomcat installation directory
- `JAVA_HOME` - Java 17 JDK path
- `HEALTH_CHECK_RETRIES` - Number of health check attempts
- `NOTIFY_EMAIL` - Email for deployment notifications

### Monitoring Tomcat Deployment
```bash
# Check deployment status
tail -f ${TOMCAT_HOME}/logs/catalina.out

# View application logs
tail -f ${TOMCAT_HOME}/logs/my-testing-app.log

# Health check
curl http://localhost:8080/my-app

# Check Tomcat process
ps aux | grep tomcat
```

## 📊 Deployment Scripts

- **deploy-to-tomcat**: Deploy WAR to Tomcat with rollback
- **deploy-war-to-tomcat**: WAR deployment via Tomcat Manager
- **deploy-env**: Multi-environment deployer with Helm
- **docker-ci-cd**: Docker build and push
- **docker-swarm-ci-cd**: Docker Swarm deployment

## 🔍 Monitoring

### Kubernetes
```bash
# Check deployment
kubectl describe deployment my-app -n production

# View logs
kubectl logs -l app=my-app -n production

# Port forward
kubectl port-forward svc/my-app 8080:8080 -n production

# Access application
curl http://localhost:8080
```

### Jenkins
- View build console output
- Check pipeline stages
- Review SonarQube reports
- Monitor test results

## 🔐 Security Best Practices

- Store credentials in Jenkins credential store
- Use environment variables for sensitive data
- Scan Docker images for vulnerabilities
- Enable Kubernetes RBAC
- Use network policies
- Apply resource limits

## 📚 Documentation

All pipeline configurations are documented in their respective files. Check each pipeline definition for specific configuration details.

## 👤 Author

Created by [bhandhuvistu](https://github.com/bhandhuvistu)

**Last Updated**: 2024