#!/bin/bash
# Trigger Testing Job in Jenkins

JENKINS_URL=${JENKINS_URL:-"http://localhost:8080"}
JOB_NAME=${1:-"testing-job"}
GIT_BRANCH=${2:-"main"}
TEST_TYPE=${3:-"all"}
GENERATE_REPORT=${4:-"true"}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Validate Jenkins URL
if [[ ! $JENKINS_URL =~ ^https?:// ]]; then
    JENKINS_URL="http://${JENKINS_URL}"
fi

JENKINS_URL="${JENKINS_URL%/}"

# Build trigger URL
TRIGGER_URL="${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters"

echo -e "${BLUE}════════════════════════════════════${NC}"
echo -e "${BLUE}Jenkins Testing Job Trigger${NC}"