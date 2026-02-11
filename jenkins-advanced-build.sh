#!/bin/bash

# Advanced Jenkins Build Script for Maven + Docker + Deployment
# Usage in Jenkins: Execute Shell -> copy this script

set -e  # Exit on error
set -u  # Exit on undefined variable

# ============================================
# CONFIGURATION
# ============================================
APP_NAME="my-testing-app"
DOCKER_REGISTRY="docker.io"
DOCKER_IMAGE="${DOCKER_REGISTRY}/${APP_NAME}"
TOMCAT_HOME="/opt/tomcat"

# ============================================
# HELPER FUNCTIONS
# ============================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# ============================================
# BUILD PHASE
# ============================================

log "Starting Jenkins Build Job"
log "Job: ${JOB_NAME} #${BUILD_NUMBER}"
log "Workspace: ${WORKSPACE}"
log "Branch: ${GIT_BRANCH:-master}"
log "Commit: ${GIT_COMMIT:-N/A}"

cd "${WORKSPACE}"

# Verify Maven
if ! command -v mvn &> /dev/null; then
    error "Maven not found. Please install Maven."
fi

log "Building with Maven..."
mvn clean package -DskipTests || error "Maven build failed"
log "✓ Maven build successful"

# ============================================
# DOCKER BUILD PHASE
# ============================================

log "Building Docker image..."
BUILD_TAG="${DOCKER_IMAGE}:${BUILD_NUMBER}"
LATEST_TAG="${DOCKER_IMAGE}:latest"

docker build -t "${BUILD_TAG}" -t "${LATEST_TAG}" . || error "Docker build failed"
log "✓ Docker image built: ${BUILD_TAG}"

# ============================================
# DEPLOYMENT PHASE
# ============================================

log "Deploying to Tomcat..."

# Find WAR file
WAR_FILE=$(find "${WORKSPACE}/target" -name "*.war" | head -1)
if [ -z "${WAR_FILE}" ]; then
    error "No WAR file found in target directory"
fi

log "Found WAR: ${WAR_FILE}"

# Copy to Tomcat
cp "${WAR_FILE}" "${TOMCAT_HOME}/webapps/" || error "Failed to copy WAR to Tomcat"
log "✓ WAR deployed to Tomcat"

# ============================================
# VERIFICATION
# ============================================

log "Verifying deployment..."
sleep 5

# Check Tomcat logs
if [ -f "${TOMCAT_HOME}/logs/catalina.out" ]; then
    log "Latest Tomcat logs:"
    tail -20 "${TOMCAT_HOME}/logs/catalina.out"
fi

log "✓ Deployment verification complete"

# ============================================
# POST BUILD ACTIONS
# ============================================

log "Build Summary:"
log "  Job: ${JOB_NAME} #${BUILD_NUMBER}"
log "  Status: SUCCESS"
log "  Duration: $((SECONDS / 60)) minutes"
log "  Build URL: ${BUILD_URL}"
log "  Artifact: ${WAR_FILE##*/}"
log "  Docker Image: ${BUILD_TAG}"

# Send notification (example)
# curl -X POST http://slack-webhook-url -d "@notification.json"

log "Build Complete!"
