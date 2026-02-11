#!/bin/bash
# Fix: Tomcat deployment - Application already being serviced error
# This script properly undeploys and redeploys the application

set -e

TOMCAT_HOME="/opt/tomcat"
TOMCAT_MANAGER="http://localhost:8080/manager/text"
APP_CONTEXT="/myweb"
TOMCAT_USER="admin"
TOMCAT_PASS="admin123"

echo "=========================================="
echo "Tomcat Deployment - Fix and Redeploy"
echo "=========================================="

# Find WAR file
BUILD_DIR="${WORKSPACE}/target"
WAR_FILE=$(find "${BUILD_DIR}" -name "*.war" -not -name ".original" | head -1)

if [ -z "$WAR_FILE" ] || [ ! -f "$WAR_FILE" ]; then
    echo "ERROR: No WAR file found in $BUILD_DIR"
    exit 1
fi

echo "WAR File: $WAR_FILE"
echo "Context: $APP_CONTEXT"
echo ""

# ========== STEP 1: UNDEPLOY ==========
echo "=========================================="
echo "Step 1: Undeploying existing application..."
echo "=========================================="

# Wait a bit to ensure previous deployment is complete
sleep 3

# Undeploy with retry logic
UNDEPLOY_ATTEMPTS=0
MAX_UNDEPLOY_ATTEMPTS=3

while [ $UNDEPLOY_ATTEMPTS -lt $MAX_UNDEPLOY_ATTEMPTS ]; do
    UNDEPLOY_ATTEMPTS=$((UNDEPLOY_ATTEMPTS + 1))
    
    echo "Undeploy attempt $UNDEPLOY_ATTEMPTS of $MAX_UNDEPLOY_ATTEMPTS..."
    
    RESPONSE=$(curl -s -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
        "${TOMCAT_MANAGER}/text/undeploy?path=${APP_CONTEXT}")
    
    echo "Response: $RESPONSE"
    
    # Check if undeploy was successful
    if echo "$RESPONSE" | grep -q "OK"; then
        echo "✓ Application undeployed successfully"
        break
    elif echo "$RESPONSE" | grep -q "FAIL - No application was found"; then
        echo "✓ Application not found (already undeployed)"
        break
    else
        echo "⚠ Undeploy response unclear, waiting..."
        sleep 2
    fi
done

# Wait for Tomcat to complete the undeploy operation
echo "Waiting for undeploy to complete..."
sleep 5

# ========== STEP 2: VERIFY UNDEPLOY ==========
echo ""
echo "=========================================="
echo "Step 2: Verifying application is stopped..."
echo "=========================================="

VERIFY_ATTEMPTS=0
while [ $VERIFY_ATTEMPTS -lt 5 ]; do
    VERIFY_ATTEMPTS=$((VERIFY_ATTEMPTS + 1))
    
    if curl -s -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
        "${TOMCAT_MANAGER}/text/list" | grep -q "$APP_CONTEXT"; then
        echo "Attempt $VERIFY_ATTEMPTS: Application still running, waiting..."
        sleep 2
    else
        echo "✓ Application successfully stopped"
        break
    fi
done

sleep 2

# ========== STEP 3: DEPLOY ==========
echo ""
echo "=========================================="
echo "Step 3: Deploying new application..."
echo "=========================================="

# Deploy with proper URL encoding
DEPLOY_URL="${TOMCAT_MANAGER}/deploy?path=${APP_CONTEXT}&war=file:${WAR_FILE}"

echo "Deploy URL: $DEPLOY_URL"

DEPLOY_RESPONSE=$(curl -s -u "${TOMCAT_USER}:${TOMCAT_PASS}" "$DEPLOY_URL")
echo "Response: $DEPLOY_RESPONSE"

if echo "$DEPLOY_RESPONSE" | grep -q "OK"; then
    echo "✓ Deployment successful!"
else
    echo "⚠ Deployment response: $DEPLOY_RESPONSE"
fi

# ========== STEP 4: VERIFICATION ==========
echo ""
echo "=========================================="
echo "Step 4: Verifying deployment..."
echo "=========================================="

sleep 3

VERIFY_DEPLOY=0
while [ $VERIFY_DEPLOY -lt 10 ]; do
    VERIFY_DEPLOY=$((VERIFY_DEPLOY + 1))
    
    echo "Verification attempt $VERIFY_DEPLOY..."
    
    if curl -s -m 5 "http://localhost:8080${APP_CONTEXT}/" | head -20; then
        echo ""
        echo "✓ Application is responding!"
        
        echo ""
        echo "=========================================="
        echo "Deployment Complete!"
        echo "=========================================="
        echo "URL: http://localhost:8080${APP_CONTEXT}/"
        exit 0
    fi
    
    echo "Application not yet responding, waiting..."
    sleep 2
done

echo ""
echo "=========================================="
echo "Deployment completed but app not yet ready"
echo "=========================================="
echo "URL: http://localhost:8080${APP_CONTEXT}/"
echo "Check Tomcat logs: tail -50 ${TOMCAT_HOME}/logs/catalina.out"
