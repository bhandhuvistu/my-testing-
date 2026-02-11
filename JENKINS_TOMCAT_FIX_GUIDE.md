# Jenkins Job Configuration Guide - Fix Tomcat Deployment

## Problem
Jenkins build succeeds but deployment fails with:
```
HTTP request failed, response code: 404
The requested resource [/manager/text/list] is not available
```

## Root Cause
Tomcat Manager application is not properly configured or running.

## Solutions

### Solution A: Fix Tomcat Manager (Recommended for production)

#### Step 1: Run the fix script
```bash
sudo bash /home/ubuntu/my-testing-/fix-tomcat-manager.sh
```

Or manually:

```bash
# 1. Stop Tomcat
/opt/tomcat/bin/shutdown.sh
sleep 2

# 2. Edit tomcat-users.xml
sudo vi /opt/tomcat/conf/tomcat-users.xml

# Add these lines inside <tomcat-users> tag:
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<user username="admin" password="admin123" roles="manager-script,manager-jmx"/>

# 3. Start Tomcat
/opt/tomcat/bin/startup.sh

# 4. Verify Manager works
curl -u admin:admin123 http://localhost:8080/manager/text/list
```

#### Step 2: Update Jenkins Job Configuration

1. Go to **Jenkins** → **Testing** → **Configure**
2. Scroll to **Post-build Actions** → **Deploy war/ear to a container**
3. Update the following:
   - **Manager URL:** `http://localhost:8080`
   - **Username:** `jenkins`
   - **Password:** `jenkins123`
   - **WAR/EAR files:** `target/my-testing-app*.war`
   - **Context path:** `myweb`
4. Click **Save**
5. Click **Build Now**

#### Step 3: Verify

```bash
curl -u admin:admin123 http://localhost:8080/manager/text/list
```

Should output:
```
OK - Server information
/myweb:running:0:my-testing-app-1.0.0.war
```

---

### Solution B: Use Direct Deployment (Faster, use in Jenkins)

This approach **bypasses Tomcat Manager** and deploys directly to Tomcat webapps folder.

#### Step 1: Update Jenkins Job to use direct deployment

1. Go to **Jenkins** → **Testing** → **Configure**
2. Go to **Build** section
3. Find existing **Execute Shell** step, **DELETE it**
4. Add new **Execute Shell** step with:

```bash
bash "$WORKSPACE/jenkins-build-deploy.sh"
```

5. **Remove or disable** the **Post-build Actions** → **Deploy war/ear to a container** step
6. Click **Save**
7. Click **Build Now**

#### How it works:
- Builds with Maven
- Stops Tomcat
- Copies WAR directly to webapps folder
- Starts Tomcat
- Verifies application is running

#### Benefits:
- ✓ No Tomcat Manager needed
- ✓ Faster deployment
- ✓ More reliable
- ✓ Works with any Tomcat version

### Solution C: Hybrid Approach (Best for CI/CD)

Combine both approaches:

1. **First build**: Use Solution B (direct deployment)
2. **Subsequent builds**: Use Solution A (Tomcat Manager)

Create two build steps in Jenkins:

**Build Step 1 - Build & Deploy:**
```bash
bash "$WORKSPACE/jenkins-build-deploy.sh"
```

**Build Step 2 - Verify (optional):**
```bash
curl -s -m 10 http://localhost:8080/myweb/ | head -20
```

---

## Available Scripts in Repository

| Script | Purpose |
|--------|---------|
| `fix-tomcat-manager.sh` | Fixes Tomcat Manager configuration |
| `jenkins-build-deploy.sh` | Builds + deploys directly to Tomcat |
| `jenkins-simple-build.sh` | Builds with Maven only |
| `deploy-tomcat-manual.sh` | Manual Tomcat deployment |

---

## Troubleshooting Checklist

- [ ] Tomcat is running: `ps aux \| grep tomcat`
- [ ] Port 8080 is open: `netstat -tulpn \| grep 8080`
- [ ] Manager is accessible: `curl http://localhost:8080/`
- [ ] Manager API works: `curl -u admin:admin123 http://localhost:8080/manager/text/list`
- [ ] Jenkins job has correct script
- [ ] Jenkins job has correct Tomcat credentials
- [ ] Check Tomcat logs: `tail -100 /opt/tomcat/logs/catalina.out`

---

## Quick Fix Commands

```bash
# Check Tomcat status
systemctl status tomcat || ps aux | grep tomcat

# Check if manager is working
curl -u admin:admin123 http://localhost:8080/manager/text/list

# View Tomcat logs
tail -50 /opt/tomcat/logs/catalina.out

# Restart Tomcat
/opt/tomcat/bin/shutdown.sh && sleep 2 && /opt/tomcat/bin/startup.sh

# Verify application is running
curl http://localhost:8080/myweb/
```

---

## Recommended Next Steps

1. **Run the fix script first:**
   ```bash
   sudo bash /home/ubuntu/my-testing-/fix-tomcat-manager.sh
   ```

2. **Try your Jenkins job again** (Build #9)

3. **If still fails, switch to Solution B:**
   - Change Jenkins job Execute Shell to use `jenkins-build-deploy.sh`
   - Disable "Deploy war/ear to container" post-build action

4. **Monitor the build:**
   - Check Jenkins console output
   - Check Tomcat logs: `tail -50 /opt/tomcat/logs/catalina.out`

---

## Testing Deployment Manually

```bash
# 1. Build locally
mvn clean install -DskipTests

# 2. Find WAR file
ls -la target/*.war

# 3. Stop Tomcat
/opt/tomcat/bin/shutdown.sh
sleep 2

# 4. Deploy
cp target/my-testing-app-*.war /opt/tomcat/webapps/myweb.war

# 5. Start Tomcat
/opt/tomcat/bin/startup.sh
sleep 5

# 6. Test
curl http://localhost:8080/myweb/
```

---

## Notes

- Default Tomcat users created: `admin` and `jenkins`
- Passwords should be changed in production
- Tomcat needs to be restarted for config changes
- Check file permissions if deployment fails
- WAR file should be at least 1KB (check with `ls -la target/`)
