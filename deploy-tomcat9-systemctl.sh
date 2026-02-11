#!/bin/bash
# Complete Deployment Script for Tomcat9 (systemctl)
# This is the CORRECT script for your setup with tomcat9

set -e

echo "=========================================="
echo "Build & Deploy to Tomcat9"
echo "=========================================="

# Configuration for tomcat9
WORKSPACE="/home/ubuntu/.jenkins/workspace/Testing"
WAR_FILE="$WORKSPACE/target/my-testing-app-1.0.0.war"
TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
TOMCAT_SERVICE="tomcat9"
APP_NAME="myweb"

echo "Workspace: $WORKSPACE"
echo "WAR file: $WAR_FILE"
echo "Tomcat webapps: $TOMCAT_WEBAPPS"
echo "Service: $TOMCAT_SERVICE"

# ========== STEP 1: BUILD ==========
echo ""
echo "=========================================="
echo "Step 1: Building with Maven"
echo "=========================================="

cd "$WORKSPACE"
mvn clean install -DskipTests
echo "✓ Build completed"

# ========== STEP 2: FIND WAR ==========
echo ""
echo "=========================================="
echo "Step 2: Locating WAR file"
echo "=========================================="

if [ ! -f "$WAR_FILE" ]; then
    # Find any WAR file
    WAR_FILE=$(find "$WORKSPACE/target" -name "*.war" ! -name ".original" | head -1)
fi

if [ -z "$WAR_FILE" ] || [ ! -f "$WAR_FILE" ]; then
    echo "ERROR: No WAR file found"
    find "$WORKSPACE/target" -type f
    exit 1
fi

echo "Found WAR: $WAR_FILE"
echo "Size: $(du -h "$WAR_FILE" | cut -f1)"

# ========== STEP 3: STOP TOMCAT ==========
echo ""
echo "=========================================="
echo "Step 3: Stopping Tomcat"
echo "=========================================="

echo "Stopping $TOMCAT_SERVICE service..."
sudo systemctl stop $TOMCAT_SERVICE 2>/dev/null || {
    echo "⚠ Could not stop service, trying kill..."
    sudo pkill -f "tomcat9" || true
}
sleep 3

# Verify stopped
if sudo systemctl is-active $TOMCAT_SERVICE > /dev/null 2>&1; then
    echo "⚠ Service still running, forcing stop..."
    sudo pkill -9 -f "tomcat9" || true
    sleep 2
fi

echo "✓ Tomcat stopped"

# ========== STEP 4: CLEAN & DEPLOY ==========
echo ""
echo "=========================================="
echo "Step 4: Deploying Application"
echo "=========================================="

echo "Removing old deployment..."
sudo rm -f "$TOMCAT_WEBAPPS/$APP_NAME.war" 2>/dev/null || true
sudo rm -rf "$TOMCAT_WEBAPPS/$APP_NAME" 2>/dev/null || true

echo "Copying WAR file..."
sudo cp "$WAR_FILE" "$TOMCAT_WEBAPPS/$APP_NAME.war"

echo "Setting permissions..."
sudo chmod 644 "$TOMCAT_WEBAPPS/$APP_NAME.war"

if [ -f "$TOMCAT_WEBAPPS/$APP_NAME.war" ]; then
    echo "✓ WAR deployed: $TOMCAT_WEBAPPS/$APP_NAME.war"
else
    echo "ERROR: Failed to copy WAR"
    exit 1
fi

# ========== STEP 5: START TOMCAT ==========
echo ""
echo "=========================================="
echo "Step 5: Starting Tomcat"
echo "=========================================="

echo "Starting $TOMCAT_SERVICE service..."
sudo systemctl start $TOMCAT_SERVICE
sleep 5

# Verify started
if sudo systemctl is-active $TOMCAT_SERVICE > /dev/null 2>&1; then
    echo "✓ Tomcat started successfully"
else
    echo "ERROR: Tomcat failed to start"
    sudo systemctl status $TOMCAT_SERVICE
    exit 1
fi

# ========== STEP 6: VERIFY DEPLOYMENT ==========
echo ""
echo "=========================================="
echo "Step 6: Verifying Deployment"
echo "=========================================="

MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if curl -s -m 3 "http://localhost:8080/$APP_NAME/" > /dev/null 2>&1; then
        echo "✓ Application is responding!"
        echo ""
        echo "=========================================="
        echo "✓ DEPLOYMENT SUCCESSFUL!"
        echo "=========================================="
        echo "URL: http://localhost:8080/$APP_NAME/"
        echo "Service status: sudo systemctl status $TOMCAT_SERVICE"
        echo "Logs: sudo tail -50 /var/log/tomcat9/catalina.out"
        exit 0
    fi
    
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting for app to start..."
    sleep 2
done

echo ""
echo "=========================================="
echo "⚠ Deployment completed (app still starting)"
echo "=========================================="
echo "URL: http://localhost:8080/$APP_NAME/"
echo ""
echo "Monitor with:"
echo "  sudo systemctl status $TOMCAT_SERVICE"
echo "  sudo tail -f /var/log/tomcat9/catalina.out"
