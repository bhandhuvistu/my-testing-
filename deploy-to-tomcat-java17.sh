#!/bin/bash
# Tomcat Deployment Script for Java 17
# Optimized for Tomcat 10.x with automatic health checks
set -e

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/tomcat-config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check Java version
check_java_version() {
    log "Checking Java version..."
    if ! command -v "$JAVA_HOME/bin/java" &> /dev/null; then
        error "Java not found at $JAVA_HOME"
        exit 1
    fi
    
    JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | grep -oP '(?<=version ")[^"]+')
    log "Using Java: $JAVA_VERSION"
    
    if [[ ! "$JAVA_VERSION" =~ ^17 ]]; then
        warn "Expected Java 17, but found $JAVA_VERSION"
    fi
}

# Find WAR file
find_war_file() {
    log "Looking for WAR file..."
    
    if [ ! -d "$WAR_LOCATION" ]; then
        error "WAR location not found: $WAR_LOCATION"
        error "Please build the project first: mvn clean package"
        exit 1
    fi
    
    WAR_FILE=$(ls -t "$WAR_LOCATION"/$WAR_FILENAME 2>/dev/null | head -1)
    
    if [ -z "$WAR_FILE" ]; then
        error "No WAR file found matching: $WAR_FILENAME"
        exit 1
    fi
    
    log "Found WAR file: $(basename "$WAR_FILE")"
}

# Check Tomcat status
check_tomcat_status() {
    if pgrep -f "$TOMCAT_HOME" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Stop Tomcat gracefully
stop_tomcat() {
    log "Stopping Tomcat..."
    
    if ! check_tomcat_status; then
        warn "Tomcat is not running"
        return 0
    fi
    
    if [ -f "${TOMCAT_HOME}/bin/catalina.sh" ]; then
        "${TOMCAT_HOME}/bin/catalina.sh" stop
    else
        error "catalina.sh not found"
        return 1
    fi
    
    # Wait for Tomcat to stop
    WAIT_TIME=0
    while check_tomcat_status && [ $WAIT_TIME -lt $DEPLOY_TIMEOUT ]; do
        sleep 1
        ((WAIT_TIME++))
    done
    
    if check_tomcat_status; then
        warn "Tomcat did not stop gracefully, force killing..."
        pkill -f "$TOMCAT_HOME"
        sleep 2
    fi
    
    log "Tomcat stopped"
}

# Backup current deployment
backup_deployment() {
    local DEPLOYED_WAR="${TOMCAT_HOME}/webapps/${APP_NAME}.war"
    local DEPLOYED_DIR="${TOMCAT_HOME}/webapps/${APP_NAME}"
    
    if [ -f "$DEPLOYED_WAR" ] || [ -d "$DEPLOYED_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        if [ -f "$DEPLOYED_WAR" ]; then
            log "Backing up existing WAR: ${APP_NAME}-${BACKUP_TIMESTAMP}.war"
            cp "$DEPLOYED_WAR" "${BACKUP_DIR}/${APP_NAME}-${BACKUP_TIMESTAMP}.war"
        fi
        
        if [ -d "$DEPLOYED_DIR" ]; then
            log "Backing up existing deployment directory"
            cp -r "$DEPLOYED_DIR" "${BACKUP_DIR}/${APP_NAME}_${BACKUP_TIMESTAMP}"
        fi
        
        log "Backup completed"
    fi
}

# Deploy new WAR
deploy_war() {
    log "Deploying new WAR file..."
    
    # Remove existing deployment
    rm -f "${TOMCAT_HOME}/webapps/${APP_NAME}.war"
    rm -rf "${TOMCAT_HOME}/webapps/${APP_NAME}"
    
    # Copy new WAR
    cp "$WAR_FILE" "${TOMCAT_HOME}/webapps/${APP_NAME}.war"
    log "WAR deployed to ${TOMCAT_HOME}/webapps/${APP_NAME}.war"
}

# Start Tomcat
start_tomcat() {
    log "Starting Tomcat..."
    
    if [ ! -f "${TOMCAT_HOME}/bin/catalina.sh" ]; then
        error "catalina.sh not found"
        return 1
    fi
    
    "${TOMCAT_HOME}/bin/catalina.sh" start
    log "Tomcat startup command sent"
}

# Health check
health_check() {
    log "Performing health check..."
    
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $HEALTH_CHECK_RETRIES ]; do
        sleep $HEALTH_CHECK_INTERVAL
        
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL" 2>/dev/null || echo "000")
        
        if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "302" ]; then
            log "Health check passed! (HTTP $RESPONSE)"
            return 0
        fi
        
        ((RETRY_COUNT++))
        log "Health check attempt $RETRY_COUNT/$HEALTH_CHECK_RETRIES (HTTP $RESPONSE)"
    done
    
    error "Health check failed after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Rollback from backup
rollback() {
    error "Deployment failed! Rolling back..."
    
    stop_tomcat
    
    if [ -d "$BACKUP_DIR" ]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -1)
        
        if [ -n "$LATEST_BACKUP" ]; then
            log "Restoring from backup: $LATEST_BACKUP"
            
            if [[ "$LATEST_BACKUP" == *.war ]]; then
                cp "${BACKUP_DIR}/${LATEST_BACKUP}" "${TOMCAT_HOME}/webapps/${APP_NAME}.war"
            else
                cp -r "${BACKUP_DIR}/${LATEST_BACKUP}" "${TOMCAT_HOME}/webapps/${APP_NAME}"
            fi
            
            start_tomcat
            sleep 10
            
            if health_check; then
                log "Rollback successful!"
                return 0
            fi
        fi
    fi
    
    error "Rollback failed"
    return 1
}

# Cleanup old backups (keep last 5)
cleanup_backups() {
    if [ -d "$BACKUP_DIR" ]; then
        log "Cleaning up old backups (keeping last 5)..."
        ls -t "$BACKUP_DIR" | tail -n +6 | xargs -r -I {} rm -rf "${BACKUP_DIR}/{}"
    fi
}

# Send notification
notify() {
    if [ "$NOTIFY_ON_FAILURE" = "true" ] && [ -n "$NOTIFY_EMAIL" ]; then
        echo "$1" | mail -s "Tomcat Deployment Notification" "$NOTIFY_EMAIL"
    fi
}

# Main deployment process
main() {
    log "=========================================="
    log "Tomcat Deployment Script (Java 17)"
    log "=========================================="
    
    check_java_version
    find_war_file
    
    log "Deployment Configuration:"
    log "  Tomcat Home: $TOMCAT_HOME"
    log "  Application: $APP_NAME"
    log "  Context Path: $APP_CONTEXT_PATH"
    log "  WAR File: $(basename "$WAR_FILE")"
    log ""
    
    stop_tomcat
    backup_deployment
    deploy_war
    start_tomcat
    
    if health_check; then
        log "=========================================="
        log "Deployment completed successfully!"
        log "Application URL: http://localhost:${TOMCAT_PORT}${APP_CONTEXT_PATH}/"
        log "=========================================="
        cleanup_backups
        notify "Deployment successful"
        return 0
    else
        log "=========================================="
        error "Deployment failed!"
        log "=========================================="
        rollback
        EXIT_CODE=$?
        notify "Deployment failed - rollback executed"
        return $EXIT_CODE
    fi
}

# Run main function
main
