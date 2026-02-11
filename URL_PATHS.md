# Application URL Paths - Quick Reference

## 1. Tomcat Deployment

### After running: `./deploy-to-tomcat-java17.sh`

**URL Path:**
```
http://localhost:8080/my-app
```

**Where:**
- `localhost` = Server hostname
- `8080` = Tomcat port (configured in tomcat-config.sh)
- `/my-app` = Application context path (from APP_CONTEXT_PATH)

**Verify it's running:**
```bash
curl http://localhost:8080/my-app
curl -I http://localhost:8080/my-app  # Check headers only
```

**View logs:**
```bash
tail -f $TOMCAT_HOME/logs/catalina.out
```

---

## 2. Docker Container (Tomcat)

### After: `docker build -f Dockerfile.tomcat -t my-app-tomcat:1.0 .`

**URL Path:**
```
http://localhost:8080/my-app
```

**Run command:**
```bash
docker run -p 8080:8080 my-app-tomcat:1.0
```

**Check if running:**
```bash
docker ps | grep my-app-tomcat
curl http://localhost:8080/my-app
```

**View logs:**
```bash
docker logs -f <container-id>
```

---

## 3. Docker Container (Java Standalone)

### After: `docker build -t my-testing-app:1.0 .`

**URL Path:**
```
http://localhost:8080
```

**Note:** Context path depends on app.jar deployment, not /my-app

**Run command:**
```bash
docker run -p 8080:8080 my-testing-app:1.0
```

---

## 4. Kubernetes (Helm)

### After: `helm install my-app ./helm/node-app -n production`

**Default URL (ClusterIP):**
```bash
kubectl port-forward svc/my-app 8080:8080 -n production
# Then access: http://localhost:8080
```

**LoadBalancer (if enabled) - Get external IP:**
```bash
kubectl get svc my-app -n production

# Look for EXTERNAL-IP column
# URL: http://<EXTERNAL-IP>:8080
```

**NodePort (if configured):**
```bash
kubectl get svc my-app -n production

# Get NodePort number from PORT(S) column
# URL: http://<node-ip>:<node-port>
```

**View logs:**
```bash
kubectl logs -l app=my-app -n production
```

---

## 5. Finding Services in Kubernetes

### List all services with their URLs:
```bash
# Get service details
kubectl get svc -n production

# Describe specific service
kubectl describe svc my-app -n production

# Port forward for access
kubectl port-forward svc/my-app 8080:8080 -n production
```

### Output example:
```
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)
my-app           LoadBalancer   10.0.0.100     203.0.0.1      8080:30087/TCP
```

**Accessing the service:**
- Internal (from cluster): `http://my-app.production:8080`
- External (LoadBalancer): `http://203.0.0.1:8080`
- Local port-forward: `http://localhost:8080`

---

## 6. Multi-Environment URLs

### Development (dev)
```bash
./deploy-env dev 1.0.0

# Access via port-forward
kubectl port-forward svc/my-app 8080:8080 -n dev
# URL: http://localhost:8080
```

### Staging
```bash
./deploy-env staging 1.0.0

# Access via port-forward
kubectl port-forward svc/my-app 8080:8080 -n staging
# URL: http://localhost:8080
```

### Production
```bash
./deploy-env prod 1.0.0

# Check LoadBalancer external IP
kubectl get svc -n production

# URL: http://<external-ip>:8080
```

---

## 7. Finding Your Deployment Method

### Check what's running:

**Tomcat process:**
```bash
ps aux | grep tomcat
curl http://localhost:8080/my-app
```

**Docker container:**
```bash
docker ps
docker inspect <container-id>
curl http://localhost:8080/my-app
```

**Kubernetes pod:**
```bash
kubectl get pods -A
kubectl get svc -A
```

---

## 8. Troubleshooting URL Access

### If URL doesn't work, check:

**1. Is the service running?**
```bash
# For Tomcat
ps aux | grep tomcat

# For Docker
docker ps

# For Kubernetes
kubectl get pods -n production
kubectl get svc -n production
```

**2. Check logs for errors:**
```bash
# Tomcat
tail -f $TOMCAT_HOME/logs/catalina.out

# Docker
docker logs <container-id>

# Kubernetes
kubectl logs <pod-name> -n production
```

**3. Verify port accessibility:**
```bash
# Check if port is listening
netstat -tuln | grep 8080
# or
ss -tuln | grep 8080
```

**4. Verify application deployed:**
```bash
# Tomcat
ls $TOMCAT_HOME/webapps/my-app*

# Docker
docker inspect <container-id> | grep WorkingDir

# Kubernetes
kubectl describe pod <pod-name> -n production
```

**5. Check firewall:**
```bash
# Allow port 8080
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# Or for UFW
sudo ufw allow 8080
```

---

## 9. Quick Summary Table

| Deployment | URL | Command |
|---|---|---|
| **Tomcat** | `http://localhost:8080/my-app` | `./deploy-to-tomcat-java17.sh` |
| **Docker (Tomcat)** | `http://localhost:8080/my-app` | `docker run -p 8080:8080 my-app-tomcat:1.0` |
| **Docker (Standalone)** | `http://localhost:8080` | `docker run -p 8080:8080 my-testing-app:1.0` |
| **Kubernetes (Dev)** | `http://localhost:8080` | `./deploy-env dev 1.0.0` + port-forward |
| **Kubernetes (Prod)** | `http://<external-ip>:8080` | `./deploy-env prod 1.0.0` |

---

## 10. Getting Application Details

**Web App Content:**
```bash
# Home page
curl http://localhost:8080/my-app/

# API endpoint
curl http://localhost:8080/my-app/api

# Health check (Kubernetes)
curl http://localhost:8080/my-app/health
```

**Response examples:**
- `200 OK` = Application is running
- `302 Found` = Redirect (may need to follow)
- `404 Not Found` = Wrong URL path
- `Connection refused` = Service not running
