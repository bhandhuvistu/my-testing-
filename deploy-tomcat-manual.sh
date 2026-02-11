#!/bin/bash
# Manual Tomcat Deployment Script
# This deploys WAR file without using Tomcat Manager

set -e

TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat}"
TOMCAT_WEBAPPS="${TOMCAT_HOME}/webapps"
BUILD_DIR="${WORKSPACE}/target"
APP_NAME="my-testing-app"

# Find WAR file
WAR_FILE=$(find "${BUILD_DIR}" -name "*.war" | head -1)

if [ -z "${WAR_FILE}" ]; then
    echo "ERROR: No WAR file found in ${BUILD_DIR}"
    exit 1
fi

echo "=========================================="
echo "Manual Tomcat Deployment"
echo "=========================================="
echo "WAR File: ${WAR_FILE}"
echo "Tomcat Home: ${TOMCAT_HOME}"
echo ""

# Stop Tomcat
echo "Stopping Tomcat..."
"${TOMCAT_HOME}/bin/shutdown.sh" 2>/dev/null || true
sleep 2

# Remove old deployment
echo "Removing old deployment..."
rm -rf "${TOMCAT_WEBAPPS}/ROOT"
rm -f "${TOMCAT_WEBAPPS}/ROOT.war"

# Copy new WAR
echo "Deploying new WAR..."
cp "${WAR_FILE}" "${TOMCAT_WEBAPPS}/ROOT.war"

# Start Tomcat
echo "Starting Tomcat..."
"${TOMCAT_HOME}/bin/startup.sh"
sleep 3

# Verify deployment
echo "Verifying deployment..."
if curl -f http://localhost:8080/ > /dev/null 2>&1; then
    echo "✓ Application is running!"
else
    echo "⚠ Application not responding yet (may need more time to start)"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "URL: http://localhost:8080"
