# Fix: Tomcat "Already Being Serviced" Deployment Error

## Error Message
```
FAIL - The application [/myweb] is already being serviced
FAIL - Failed to deploy application at context path [/myweb]
```

## Root Cause

This error occurs when:
1. Jenkins tries to redeploy while the previous deployment is still being processed
2. The application is locked during the undeploy/redeploy cycle
3. Multiple deployment requests are happening simultaneously

## Solutions

### Solution 1: Proper Undeploy Then Deploy (Recommended)

Use the provided fix script: `fix-tomcat-already-serviced.sh`

```bash
# Run this on Jenkins server
bash /home/ubuntu/my-testing-/fix-tomcat-already-serviced.sh
```

This script:
1. Waits for previous deployment to complete
2. Properly undeploys the application with retry logic
3. Verifies the application is fully stopped
4. Then deploys the new version
5. Verifies deployment was successful

---

### Solution 2: Restart Tomcat Before Deploy

In Tomcat Manager deployment settings, add pre-deployment script:

```bash
#!/bin/bash
# Restart Tomcat before deployment (nuclear option)

/opt/tomcat/bin/shutdown.sh
sleep 3
/opt/tomcat/bin/startup.sh
sleep 5

echo "Tomcat restarted, ready for deployment"
```

This ensures a clean slate for deployment.

---

### Solution 3: Use Different Context Paths

Instead of redeploying to `/myweb`, use versioned contexts:

- Build 1: Deploy to `/myweb-v1`
- Build 2: Deploy to `/myweb-v2`
- Build 3: Deploy to `/myweb-v3` (then remove `/myweb-v1`)

This approach:
- ✓ Avoids conflicts
- ✓ Allows zero-downtime deployments
- ✓ Easy rollback

---

### Solution 4: Direct Tomcat Deployment (Bypass Manager)

Use this script instead of Tomcat Manager:

```bash
#!/bin/bash
set -e

TOMCAT_HOME="/opt/tomcat"
TOMCAT_WEBAPPS="${TOMCAT_HOME}/webapps"
WAR_FILE="$WORKSPACE/target/*.war"
APP_CONTEXT="myweb"

# Stop Tomcat
"${TOMCAT_HOME}/bin/shutdown.sh" 2>/dev/null || true
sleep 3

# Remove old deployment
rm -rf "${TOMCAT_WEBAPPS}/${APP_CONTEXT}"
rm -f "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war"

# Copy new WAR
cp $WAR_FILE "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war"

# Start Tomcat
"${TOMCAT_HOME}/bin/startup.sh"
sleep 5

# Verify
curl -m 10 http://localhost:8080/${APP_CONTEXT}/

echo "Deployment complete!"
```

---

## Quick Fix (Immediate)

### Option A: Restart Tomcat

```bash
/opt/tomcat/bin/shutdown.sh
sleep 3
/opt/tomcat/bin/startup.sh
```

Then run Jenkins job again.

### Option B: Manually UnDeploy

```bash
curl -u admin:admin123 "http://localhost:8080/manager/text/undeploy?path=/myweb"
sleep 5
# Then run Jenkins job
```

### Option C: Remove App and Restart

```bash
rm -rf /opt/tomcat/webapps/myweb
rm -f /opt/tomcat/webapps/myweb.war
/opt/tomcat/bin/shutdown.sh
sleep 2
/opt/tomcat/bin/startup.sh
```

---

## For Jenkins Development Job

1. **Go to Jenkins** → **Development** job → **Configure**

2. **Add Build Step** (before deployment):
   ```bash
   bash /$WORKSPACE/../my-testing-/fix-tomcat-already-serviced.sh
   ```

3. Or **replace** the "Deploy war/ear to container" with Execute Shell:
   ```bash
   #!/bin/bash
   set -e
   
   TOMCAT_HOME="/opt/tomcat"
   /opt/tomcat/bin/shutdown.sh 2>/dev/null || true
   sleep 3
   
   # Find and deploy
   WAR=$(find $WORKSPACE/target -name "*.war" | head -1)
   rm -rf /opt/tomcat/webapps/myweb*
   cp "$WAR" /opt/tomcat/webapps/myweb.war
   
   /opt/tomcat/bin/startup.sh
   sleep 5
   curl http://localhost:8080/myweb/
   ```

4. **Click Save** and run again

---

## Recommended Approach

**For Development Job → Testing Job → Production:**

1. **Development job (my-app):**
   - Build with Maven
   - Archive artifact
   - Trigger Testing job with artifact

2. **Testing job (my-testing-):**
   - Receive artifact from Development
   - Build/test
   - Deploy using direct method (restart Tomcat)
   - Run tests

3. **Production job:**
   - Manual approval
   - Deploy with Tomcat Manager (graceful)

---

## Commands to Verify

```bash
# Check Tomcat status
curl http://localhost:8080/

# Check deployed apps
curl -u admin:admin123 http://localhost:8080/manager/text/list

# Check app status
curl http://localhost:8080/myweb/

# View Tomcat logs
tail -50 /opt/tomcat/logs/catalina.out
```

---

## Files in Repository

- `fix-tomcat-already-serviced.sh` - Automated fix with proper undeploy/deploy sequence
- `jenkins-build-deploy.sh` - Alternative direct deployment
- `fix-tomcat-manager.sh` - Configure Tomcat Manager

---

## Next Steps

1. Run: `bash fix-tomcat-already-serviced.sh` (on Jenkins server)
2. Run Development job again
3. If still fails, use direct deployment method (Solution 4)

Check Tomcat logs if deployment still fails:
```bash
tail -100 /opt/tomcat/logs/catalina.out
```
