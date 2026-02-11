#!/bin/bash
# Find and display application URL based on deployment method

echo "🔍 Finding Application URL..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

found_url=false

# Check 1: Tomcat Deployment
echo "${BLUE}[1/4] Checking Tomcat...${NC}"
if pgrep -f "tomcat" > /dev/null; then
    TOMCAT_PORT=$(grep "port=" /opt/tomcat/conf/server.xml 2>/dev/null | grep -oP '(?<=port=")[0-9]+' | head -1)
    TOMCAT_PORT=${TOMCAT_PORT:-8080}
    
    # Check if application is accessible
    if curl -s -f http://localhost:${TOMCAT_PORT}/my-app > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Tomcat found!${NC}"
        echo -e "  ${GREEN}URL: http://localhost:${TOMCAT_PORT}/my-app${NC}"
        echo ""
        found_url=true
    fi
fi

# Check 2: Docker Container (my-app-tomcat)
echo "${BLUE}[2/4] Checking Docker Containers...${NC}"
if command -v docker &> /dev/null && docker ps > /dev/null 2>&1; then
    # Find tomcat container
    TOMCAT_CONTAINER=$(docker ps --filter "name=.*app.*" --filter "ancestor=*tomcat*" -q 2>/dev/null | head -1)
    
    if [ -n "$TOMCAT_CONTAINER" ]; then
        DOCKER_PORT=$(docker port "$TOMCAT_CONTAINER" 2>/dev/null | grep "8080" | cut -d: -f2 || echo "8080")
        
        if curl -s -f http://localhost:${DOCKER_PORT}/my-app > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker Tomcat container found!${NC}"
            echo -e "  ${GREEN}URL: http://localhost:${DOCKER_PORT}/my-app${NC}"
            echo -e "  Container ID: $TOMCAT_CONTAINER"
            echo ""
            found_url=true
        fi
    fi
    
    # Find standalone container
    STANDALONE_CONTAINER=$(docker ps --filter "name=.*app.*" -q 2>/dev/null | grep -v tomcat | head -1)
    
    if [ -n "$STANDALONE_CONTAINER" ]; then
        DOCKER_PORT=$(docker port "$STANDALONE_CONTAINER" 2>/dev/null | grep "8080" | cut -d: -f2 || echo "8080")
        
        if curl -s -f http://localhost:${DOCKER_PORT} > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker standalone container found!${NC}"
            echo -e "  ${GREEN}URL: http://localhost:${DOCKER_PORT}${NC}"
            echo -e "  Container ID: $STANDALONE_CONTAINER"
            echo ""
            found_url=true
        fi
    fi
fi

# Check 3: Kubernetes Deployment
echo "${BLUE}[3/4] Checking Kubernetes...${NC}"
if command -v kubectl &> /dev/null; then
    # Check for my-app service in any namespace
    NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    for ns in $NAMESPACES; do
        SERVICE=$(kubectl get svc my-app -n "$ns" -o jsonpath='{.metadata.name}' 2>/dev/null)
        
        if [ "$SERVICE" = "my-app" ]; then
            SERVICE_TYPE=$(kubectl get svc my-app -n "$ns" -o jsonpath='{.spec.type}' 2>/dev/null)
            
            if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
                EXTERNAL_IP=$(kubectl get svc my-app -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
                
                if [ -n "$EXTERNAL_IP" ]; then
                    echo -e "${GREEN}✓ Kubernetes LoadBalancer found!${NC}"
                    echo -e "  ${GREEN}URL: http://${EXTERNAL_IP}:8080${NC}"
                    echo -e "  Namespace: $ns"
                    echo -e "  ${YELLOW}Tip: Use this URL to access from external network${NC}"
                    echo ""
                    found_url=true
                fi
            fi
            
            if [ -z "$found_url" ]; then
                echo -e "${GREEN}✓ Kubernetes service found!${NC}"
                echo -e "  Service: my-app (Namespace: $ns, Type: $SERVICE_TYPE)"
                echo -e "  ${YELLOW}To access, run:${NC}"
                echo -e "    kubectl port-forward svc/my-app 8080:8080 -n $ns"
                echo -e "  ${GREEN}Then visit: http://localhost:8080${NC}"
                echo ""
                found_url=true
            fi
        fi
    done
fi

# Check 4: Local port listening
echo "${BLUE}[4/4] Checking open ports...${NC}"
if command -v netstat &> /dev/null; then
    LISTENING=$(netstat -tuln 2>/dev/null | grep "8080\|8081\|8082" | awk '{print $4}' | cut -d: -f2 | sort -u)
elif command -v ss &> /dev/null; then
    LISTENING=$(ss -tuln 2>/dev/null | grep "8080\|8081\|8082" | awk '{print $4}' | cut -d: -f2 | sort -u)
fi

if [ -n "$LISTENING" ]; then
    echo -e "${YELLOW}Found open ports:${NC} $LISTENING"
    for port in $LISTENING; do
        if curl -s -f http://localhost:${port}/my-app > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Port $port responds to /my-app${NC}"
            echo -e "  URL: http://localhost:${port}/my-app"
            found_url=true
        elif curl -s -f http://localhost:${port} > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Port $port is responding${NC}"
            echo -e "  URL: http://localhost:${port}"
            found_url=true
        fi
    done
    echo ""
fi

# Summary
echo "${BLUE}═════════════════════════════════════${NC}"

if [ "$found_url" = true ]; then
    echo -e "${GREEN}✓ Application found!${NC}"
    echo ""
    echo -e "${YELLOW}Quick test:${NC}"
    echo -e "  curl http://localhost:8080/my-app"
    echo ""
else
    echo -e "${RED}✗ Application not found running${NC}"
    echo ""
    echo -e "${YELLOW}To deploy, try:${NC}"
    echo -e "  1. Tomcat: ${BLUE}./deploy-to-tomcat-java17.sh${NC}"
    echo -e "  2. Docker: ${BLUE}docker build -f Dockerfile.tomcat -t my-app-tomcat:1.0 .${NC}"
    echo -e "  3. Kubernetes: ${BLUE}./deploy-env prod 1.0.0${NC}"
    echo ""
    echo -e "${YELLOW}For more details, see: ${BLUE}URL_PATHS.md${NC}"
fi
