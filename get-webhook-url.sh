#!/bin/bash
# Get and display Jenkins Webhook URL for GitHub

echo "🔗 Jenkins GitHub Webhook Configuration"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get Jenkins URL from arguments or environment
JENKINS_URL=${1:-${JENKINS_URL:-"http://localhost:8080"}}

# Validate URL format
if [[ ! $JENKINS_URL =~ ^https?:// ]]; then
    JENKINS_URL="http://${JENKINS_URL}"
fi

# Remove trailing slash
JENKINS_URL="${JENKINS_URL%/}"

# Webhook path
WEBHOOK_PATH="/github-webhook/"
WEBHOOK_URL="${JENKINS_URL}${WEBHOOK_PATH}"

echo -e "${GREEN}Webhook URL:${NC}"
echo -e "${BLUE}$WEBHOOK_URL${NC}"
echo ""

# Detect local network IP
get_local_ip() {
    hostname -I | awk '{print $1}' || echo "127.0.0.1"
}

# If localhost, show alternative IPs
if [[ $JENKINS_URL == *"localhost"* ]] || [[ $JENKINS_URL == *"127.0.0.1"* ]]; then
    LOCAL_IP=$(get_local_ip)
    echo -e "${YELLOW}For external access, use:${NC}"
    echo -e "${BLUE}http://${LOCAL_IP}:8080${WEBHOOK_PATH}${NC}"
    echo ""
fi
