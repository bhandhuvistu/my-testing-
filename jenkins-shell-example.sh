#!/bin/bash

# Jenkins Shell Script Example
# This script demonstrates how to use Jenkins environment variables

set -e  # Exit on error

echo "=========================================="
echo "Jenkins Environment Variables Example"
echo "=========================================="

# Display build information
echo "Build Information:"
echo "  Job Name: ${JOB_NAME}"
echo "  Build Number: ${BUILD_NUMBER}"
echo "  Build ID: ${BUILD_ID}"
echo "  Build URL: ${BUILD_URL}"
echo "  Build Timestamp: ${BUILD_TIMESTAMP}"
echo "  Started by: ${BUILD_CAUSE}"
echo ""

# Display workspace info
echo "Workspace Information:"
echo "  Workspace Path: ${WORKSPACE}"
echo "  Current Directory: $(pwd)"
echo ""

# Display Git information
echo "Git Information:"
echo "  Git Commit: ${GIT_COMMIT:-'Not available'}"
echo "  Git Branch: ${GIT_BRANCH:-'Not available'}"
echo ""

# Display Node information
echo "Node Information:"
echo "  Node Name: ${NODE_NAME}"
echo "  Java Home: ${JAVA_HOME}"
echo "  Jenkins Home: ${JENKINS_HOME}"
echo ""

echo "=========================================="
echo "Running Build Steps"
echo "=========================================="

# Example: Clone repository
if [ -d ".git" ]; then
    echo "✓ Git repository found"
    echo "  Remote URL: $(git config --get remote.origin.url)"
    echo "  Current Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "  Latest Commit: $(git log -1 --oneline)"
fi

# Example: Build with Maven
if [ -f "pom.xml" ]; then
    echo "✓ Maven project found"
    echo "  Building Maven project..."
    # mvn clean package -DskipTests  # Uncomment to run
fi

# Example: Run tests
echo "✓ Would run tests here"

# Example: Deploy
echo "✓ Would deploy artifact here"

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="

# Display build log location
echo "Build Log: ${BUILD_LOG}"
echo "Workspace: ${WORKSPACE}"
