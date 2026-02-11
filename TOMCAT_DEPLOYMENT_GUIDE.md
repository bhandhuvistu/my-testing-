# Tomcat Deployment Troubleshooting Guide

## Current Issue

Build is **succeeding** ✅ but deployment is **failing** ❌

```
HTTP request failed, response code: 404
The requested resource [/manager/text/list] is not available
```

## Root Cause Analysis

The Tomcat Manager web interface is not responding to Jenkins' deployment requests.

## Solutions

### Solution 1: Fix Tomcat Manager (Recommended)

**Step 1: Check Tomcat Status**
```bash
ps aux | grep tomcat
curl -I http://localhost:8080/
```

**Step 2: Enable Tomcat Manager**

Edit `/opt/tomcat/conf/tomcat-users.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">

  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="admin" password="admin123" roles="manager-gui,manager-script"/>

</tomcat-users>
```

**Step 3: Restart Tomcat**
```bash
/opt/tomcat/bin/shutdown.sh
sleep 2
/opt/tomcat/bin/startup.sh
```

**Step 4: Verify Manager is Running**
```bash
curl -u admin:admin123 http://localhost:8080/manager/text/list
```

You should see the list of deployed apps.

**Step 5: Update Jenkins Credentials**

In Jenkins → Testing Job → Configure → Post-build Actions → Deploy war/ear to a container:
- **Container:** Tomcat 9.x Remote
- **Manager URL:** `http://localhost:8080`
- **Username:** `admin`
- **Password:** `admin123`

### Solution 2: Use Manual Deployment (Alternative)

If Tomcat Manager keeps failing, use manual deployment:

Edit Jenkins job → Configure → Build section → Add Execute Shell:

```bash
bash "$WORKSPACE/deploy-tomcat-manual.sh"
```

This script:
- Stops Tomcat
- Copies the WAR file
- Starts Tomcat again
- Verifies deployment

### Solution 3: Use Script-based Deployment

Add this post-build step in Jenkins:

```bash
#!/bin/bash
set -e

TOMCAT_HOME="/opt/tomcat"
TOMCAT_WEBAPPS="${TOMCAT_HOME}/webapps"
WAR_FILE=$(find "$WORKSPACE/target" -name "*.war" | head -1)

echo "Deploying: $WAR_FILE"

# Stop Tomcat
"${TOMCAT_HOME}/bin/shutdown.sh" || true
sleep 2

# Deploy
cp "${WAR_FILE}" "${TOMCAT_WEBAPPS}/ROOT.war"
rm -rf "${TOMCAT_WEBAPPS}/ROOT"

# Start Tomcat
"${TOMCAT_HOME}/bin/startup.sh"

echo "Deployment complete!"
```

## Verification Steps

After deployment, verify it's working:

```bash
# Check Tomcat logs
tail -50 /opt/tomcat/logs/catalina.out

# Test the application
curl http://localhost:8080/

# Check active deployments
curl -u admin:admin123 http://localhost:8080/manager/text/list
```

## Troubleshooting Commands

| Command | Purpose |
|---------|---------|
| `curl http://localhost:8080/` | Test Tomcat is running |
| `curl http://localhost:8080/manager/` | Test Manager GUI |
| `curl -u admin:admin123 http://localhost:8080/manager/text/list` | Test Manager API |
| `ps aux \| grep tomcat` | Check if Tomcat process is running |
| `netstat -tulpn \| grep 8080` | Check if port 8080 is listening |
| `tail /opt/tomcat/logs/catalina.out` | View Tomcat logs |

## Jenkins Configuration Best Practices

1. **Always use Tomcat Manager for remote deployments** (more reliable)
2. **Use manual deployment scripts for local/direct access**
3. **Keep credentials in Jenkins Credentials Store** (not hardcoded)
4. **Test credentials before saving job configuration**
5. **Monitor Tomcat logs during deployment**

## Files in This Repository

- `jenkins-simple-build.sh` - Maven build script
- `deploy-tomcat-manual.sh` - Manual Tomcat deployment
- Existing `deploy-to-tomcat` - Alternative deployment script
- Existing `tomcat-config.sh` - Tomcat configuration

## Next Steps

1. Fix Tomcat Manager credentials (Solution 1), OR
2. Switch to manual deployment script (Solution 2), OR  
3. Use inline shell script in Jenkins (Solution 3)

Run Jenkins build again after fixing!
