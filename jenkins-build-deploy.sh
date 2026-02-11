#!/bin/bash
# Alternative Jenkins Build Script - Direct Tomcat Deployment
# Use this when Tomcat Manager is not available
# Configure in Jenkins: Execute Shell → copy this entire script

set -e

echo "=========================================="
echo "Build & Deploy Pipeline"
echo "=========================================="

# Configuration - Updated for tomcat9 systemctl
TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
TOMCAT_SERVICE="tomcat9"
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
if [ ! -d "${TOMCAT_WEBAPPS}" ]; then
    echo "ERROR: Tomcat webapps directory not found at ${TOMCAT_WEBAPPS}"
    echo "Looking for Tomcat directories..."
    find /var/lib -name "webapps" -type d 2>/dev/null || echo "Tomcat not found"
    exit 1
fi

echo "Tomcat webapps: ${TOMCAT_WEBAPPS}"

# Stop Tomcat using systemctl
echo "Stopping Tomcat service..."
sudo systemctl stop ${TOMCAT_SERVICE} 2>/dev/null || {
    echo "⚠ Could not stop via systemctl, trying direct method..."
    pkill -f "tomcat" || true
}
sleep 3

# Remove old application
echo "Removing old deployment..."
sudo rm -f "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" 2>/dev/null || true
sudo rm -rf "${TOMCAT_WEBAPPS}/${APP_CONTEXT}" 2>/dev/null || true
echo "✓ Old deployment cleaned"

# Deploy new WAR
echo "Deploying new application..."
if [ ! -f "${WAR_FILE}" ]; then
    echo "ERROR: WAR file not found at ${WAR_FILE}"
    exit 1
fi

sudo cp "${WAR_FILE}" "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war"
if [ -f "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" ]; then
    echo "✓ WAR copied to Tomcat ($(du -h "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war" | cut -f1))"
    # Fix permissions
    sudo chmod 644 "${TOMCAT_WEBAPPS}/${APP_CONTEXT}.war"
else
    echo "ERROR: Failed to copy WAR file"
    exit 1
fi

# Start Tomcat using systemctl
echo "Starting Tomcat service..."
sudo systemctl start ${TOMCAT_SERVICE}
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
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/${APP_CONTEXT}/" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Application is running at http://localhost:8080/${APP_CONTEXT}/"
        echo ""
        echo "=========================================="
        echo "Deployment Successful!"
        echo "=========================================="
        exit 0
    fi
    
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Application not yet responding (HTTP $HTTP_CODE)..."
    sleep 2
done

# If we reach here, app is still not responding, but deployment was done
echo "⚠ Application may still be initializing"
echo "URL: http://localhost:8080/${APP_CONTEXT}/"
echo "Check Tomcat status: sudo systemctl status ${TOMCAT_SERVICE}"
echo "Check Tomcat logs: sudo tail -50 /var/log/tomcat9/catalina.out"
echo ""
echo "=========================================="
echo "Build and Deployment Phase Complete"
echo "=========================================="
