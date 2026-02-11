#!/bin/bash
# Fix Tomcat Manager Configuration
# This script enables Tomcat Manager application

set -e

TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat}"
TOMCAT_USERS="${TOMCAT_HOME}/conf/tomcat-users.xml"
TOMCAT_CONTEXT="${TOMCAT_HOME}/conf/Catalina/localhost"

echo "=========================================="
echo "Tomcat Manager Configuration"
echo "=========================================="
echo "Tomcat Home: ${TOMCAT_HOME}"
echo ""

# Check if Tomcat exists
if [ ! -d "${TOMCAT_HOME}" ]; then
    echo "ERROR: Tomcat not found at ${TOMCAT_HOME}"
    exit 1
fi

# Stop Tomcat
echo "Stopping Tomcat..."
if [ -f "${TOMCAT_HOME}/bin/shutdown.sh" ]; then
    "${TOMCAT_HOME}/bin/shutdown.sh" 2>/dev/null || true
    sleep 3
fi

# Backup original file
if [ -f "${TOMCAT_USERS}" ]; then
    cp "${TOMCAT_USERS}" "${TOMCAT_USERS}.backup"
    echo "✓ Backed up tomcat-users.xml"
fi

# Create new tomcat-users.xml with manager user
echo "Configuring tomcat-users.xml..."
cat > "${TOMCAT_USERS}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">

  <!-- Manager roles -->
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="manager-jmx"/>
  <role rolename="manager-status"/>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>

  <!-- Manager user for UI and script access -->
  <user username="admin" password="admin123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>

  <!-- Jenkins deployment user (minimal privileges) -->
  <user username="jenkins" password="jenkins123" roles="manager-script,manager-jmx"/>

</tomcat-users>
EOF
chmod 600 "${TOMCAT_USERS}"
echo "✓ Updated tomcat-users.xml"

# Fix manager app context if it exists
if [ -d "${TOMCAT_CONTEXT}" ]; then
    echo "Checking manager app context..."
    
    # Check if manager context exists
    if [ ! -f "${TOMCAT_CONTEXT}/manager.xml" ]; then
        echo "Creating manager context..."
        mkdir -p "${TOMCAT_CONTEXT}"
        cat > "${TOMCAT_CONTEXT}/manager.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context privileged="true">
</Context>
EOF
        echo "✓ Created manager context"
    fi
fi

# Start Tomcat
echo ""
echo "Starting Tomcat..."
"${TOMCAT_HOME}/bin/startup.sh"
sleep 5

# Verify Manager is running
echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

MANAGER_URL="http://localhost:8080/manager/text/list"
echo "Testing Tomcat Manager..."

if curl -s -u admin:admin123 "${MANAGER_URL}" | grep -q "OK"; then
    echo "✓ Tomcat Manager is working!"
    echo ""
    echo "Manager URL: http://localhost:8080/manager"
    echo "API URL: http://localhost:8080/manager/text/list"
    echo "Username: admin"
    echo "Password: admin123"
    echo ""
else
    echo "⚠ Tomcat Manager not responding yet (may need more time)"
    echo "Check logs: tail -50 ${TOMCAT_HOME}/logs/catalina.out"
fi

echo ""
echo "=========================================="
echo "Next Steps for Jenkins"
echo "=========================================="
echo ""
echo "1. Go to Jenkins → Testing Job → Configure"
echo "2. Find 'Deploy war/ear to a container' section"
echo "3. Update settings:"
echo "   - Container: Tomcat 9.x Remote"
echo "   - Manager URL: http://localhost:8080"
echo "   - Username: jenkins"
echo "   - Password: jenkins123"
echo "4. Click Save and run build again"
echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
