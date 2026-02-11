#!/bin/bash

# Script to Print ALL Jenkins Environment Variables
# Use this in Jenkins "Execute Shell" to see all available variables
# Output will be in Jenkins build log

echo "=========================================="
echo "ALL JENKINS ENVIRONMENT VARIABLES"
echo "=========================================="
echo ""

# Print all environment variables sorted
env | sort

echo ""
echo "=========================================="
echo "CUSTOM ENVIRONMENT (if set)"
echo "=========================================="
echo ""

# Print specific Jenkins variables
if [ -n "${JENKINS_HOME:-}" ]; then
    echo "Jenkins Configuration:"
    echo "  JENKINS_HOME: ${JENKINS_HOME}"
    echo "  JENKINS_URL: ${JENKINS_URL}"
    echo "  JENKINS_SERVER_COOKIE: ${JENKINS_SERVER_COOKIE}"
    echo ""
fi

# Print build info
if [ -n "${BUILD_NUMBER:-}" ]; then
    echo "Build Information:"
    echo "  BUILD_NUMBER: ${BUILD_NUMBER}"
    echo "  BUILD_ID: ${BUILD_ID}"
    echo "  BUILD_TAG: ${BUILD_TAG}"
    echo "  BUILD_URL: ${BUILD_URL}"
    echo "  BUILD_TIMESTAMP: ${BUILD_TIMESTAMP}"
    echo "  BUILD_CAUSE: ${BUILD_CAUSE}"
    echo ""
fi

# Print job info
if [ -n "${JOB_NAME:-}" ]; then
    echo "Job Information:"
    echo "  JOB_NAME: ${JOB_NAME}"
    echo "  JOB_BASE_NAME: ${JOB_BASE_NAME}"
    echo "  JOB_URL: ${JOB_URL}"
    echo ""
fi

# Print workspace
if [ -n "${WORKSPACE:-}" ]; then
    echo "Workspace Information:"
    echo "  WORKSPACE: ${WORKSPACE}"
    echo "  WORKSPACE_TMP: ${WORKSPACE_TMP}"
    echo "  PWD: $(pwd)"
    echo ""
fi

# Print Git info (if available)
if [ -n "${GIT_COMMIT:-}" ]; then
    echo "Git Information:"
    echo "  GIT_COMMIT: ${GIT_COMMIT}"
    echo "  GIT_BRANCH: ${GIT_BRANCH}"
    echo "  GIT_URL: ${GIT_URL}"
    echo "  GIT_LOCAL_BRANCH: ${GIT_LOCAL_BRANCH}"
    echo ""
fi

# Print agent/node info
if [ -n "${NODE_NAME:-}" ]; then
    echo "Node/Agent Information:"
    echo "  NODE_NAME: ${NODE_NAME}"
    echo "  EXECUTOR_NUMBER: ${EXECUTOR_NUMBER}"
    echo ""
fi

# Print user info (if available)
if [ -n "${BUILD_USER:-}" ]; then
    echo "User Information:"
    echo "  BUILD_USER: ${BUILD_USER}"
    echo "  BUILD_USER_ID: ${BUILD_USER_ID}"
    echo ""
fi

# Print Java info
if [ -n "${JAVA_HOME:-}" ]; then
    echo "Java Information:"
    echo "  JAVA_HOME: ${JAVA_HOME}"
    echo "  JAVA_VERSION: $(java -version 2>&1 | head -1)"
    echo ""
fi

# Print PATH
echo "System PATH:"
echo "  PATH: ${PATH}"
echo ""

echo "=========================================="
echo "End of Environment Variables"
echo "=========================================="
