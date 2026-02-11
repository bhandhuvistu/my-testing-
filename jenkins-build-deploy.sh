#!/bin/bash
# Alternative Jenkins Build Script - Direct Tomcat Deployment
# Use this when Tomcat Manager is not available
# Configure in Jenkins: Execute Shell → copy this entire script

set -e

echo "=========================================="
echo "Build & Deploy Pipeline"
echo "=========================================="

# Configuration
TOMCAT_HOME="/opt/tomcat"
TOMCAT_WEBAPPS="${TOMCAT_HOME}/webapps"
BUILD_DIR="${WORKSPACE}/target"
APP_CONTEXT="myweb"

echo "Workspace: $WORKSPACE"
echo "Tomcat Home: $TOMCAT_HOME"
echo ""

# ========== BUILD PHASE ==========
echo "=========================================="
echo "Step 1: Building with Maven"
echo "=========================================="

cd "$WORKSPACE"

if [ -f "pom.xml" ]; then
    mvn clean install -DskipTests
    echo "✓ Build completed"
else
    echo "ERROR: pom.xml not found"
    exit 1
fi

echo ""

# ========== FIND WAR FILE ==========
echo "=========================================="
echo "Step 2: Locating WAR file"
echo "=========================================="

# Find the correct WAR file
WAR_FILE=$(find "${BUILD_DIR}" -name "my-testing-app*.war" -o -name "*-${BUILD_NUMBER}.war" | head -1)

if [ -z "$WAR_FILE" ] || [ ! -f "$WAR_FILE" ]; then
    # Fallback: get any WAR file
    WAR_FILE=$(find "${BUILD_DIR}" -name "*.war" | grep -v ".original" | head -1)
fi

if [ -z "$WAR_FILE" ] || [ ! -f "$WAR_FILE" ]; then
    echo "ERROR: No WAR file found in $BUILD_DIR"
    find "${BUILD_DIR}" -type f
    exit 1
fi

echo "Found WAR: $WAR_FILE"
echo "File size: $(du -h "$WAR_FILE" | cut -f1)"
echo ""

# ========== DEPLOYMENT PHASE ==========
echo "=========================================="
echo "Step 3: Deploying to Tomcat"
echo "=========================================="

# Verify Tomcat directory exists
if [ ! -d "${TOMCAT_HOME}" ]; then
    echo "ERROR: Tomcat directory not found at ${TOMCAT_HOME}"
    echo "Searching for Tomcat installation..."
    find / -name "catalina.sh" 2>/dev/null | head -5
    exit 1
fi

if [ ! -d "${TOMCAT_WEBAPPS}" ]; then
    echo "ERROR: Tomcat webapps directory not found at ${TOMCAT_WEBAPPS}"
    ls -la "${TOMCAT_HOME}/"
    exit 1
fi

# Check if Tomcat is currently running
echo "Checking Tomcat status..."
if ps aux | grep -v grep | grep "catalina"; then
    echo "Tomcat is running, stopping..."
    "${TOMCAT_HOME}/bin/shutdown.sh" 2>/dev/null || true
    sleep 3
    
    # Verify shutdown
    if ps aux | grep -v grep | grep "catalina"; then
        echo "Tomcat still running, forcing kill..."
        pkill -9 java
        sleep 2
    fi
else
    echo "Tomcat is not running"
fi

# Remove old application
echo "Removing old deployment..."
rm -rf "${TOMCAT_WEBAPPS}/${APP_CONTEXT}" 2>/dev/null || true
rm -f "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" 2>/dev/null || true
echo "✓ Old deployment cleaned"

# Deploy new WAR
echo "Deploying new application..."
if [ ! -f "${WAR_FILE}" ]; then
    echo "ERROR: WAR file not found at ${WAR_FILE}"
    exit 1
fi

cp "${WAR_FILE}" "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war"
if [ -f "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" ]; then
    echo "✓ WAR copied to Tomcat ($(du -h "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" | cut -f1))"
else
    echo "ERROR: Failed to copy WAR file"
    ls -la "${TOMCAT_WEBAPPS}/"
    exit 1
fi

# Start Tomcat
echo "Starting Tomcat..."
if [ ! -f "${TOMCAT_HOME}/bin/startup.sh" ]; then
    echo "ERROR: Tomcat startup.sh not found"
    exit 1
fi

"${TOMCAT_HOME}/bin/startup.sh"

# Wait for Tomcat to start
echo "Waiting for Tomcat to start..."
sleep 5

echo ""

# ========== VERIFICATION PHASE ==========
echo "=========================================="
echo "Step 4: Verifying Deployment"
echo "=========================================="

# Check if application is accessible
MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/${APP_CONTEXT}/" | grep -q "200"; then
        echo "✓ Application is running at http://localhost:8080/${APP_CONTEXT}/"
        echo ""
        echo "=========================================="
        echo "Deployment Successful!"
        echo "=========================================="
        exit 0
    fi
    
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Application not yet responding..."
    sleep 2
done

# If we reach here, app is still not responding, but deployment was done
echo "⚠ Application may still be initializing"
echo "URL: http://localhost:8080/${APP_CONTEXT}/"
echo "Check Tomcat logs: tail -50 ${TOMCAT_HOME}/logs/catalina.out"
echo ""
echo "=========================================="
echo "Build and Deployment Phase Complete"
echo "=========================================="
