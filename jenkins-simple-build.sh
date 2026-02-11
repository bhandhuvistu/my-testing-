#!/bin/bash
# Jenkins Build Script - Compatible with /bin/sh

set -e

echo "=========================================="
echo "Jenkins Build Information"
echo "=========================================="

# Build Information
echo "Job Name: ${JOB_NAME}"
echo "Build Number: ${BUILD_NUMBER}"
echo "Build ID: ${BUILD_ID}"
echo "Workspace: ${WORKSPACE}"
echo ""

# Change to workspace
cd "${WORKSPACE}"

echo "=========================================="
echo "Build Steps"
echo "=========================================="

# Check Maven
if [ -f "pom.xml" ]; then
    echo "Found pom.xml - Building with Maven..."
    mvn clean install -DskipTests
    echo "Maven build completed!"
else
    echo "No pom.xml found"
fi

echo ""
echo "=========================================="
echo "Build Completed Successfully!"
echo "=========================================="
