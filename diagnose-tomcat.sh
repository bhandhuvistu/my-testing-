#!/bin/bash
# Diagnostic script to check Tomcat installation and fix deployment issues

echo "=========================================="
echo "Tomcat Installation Diagnostic"
echo "=========================================="
echo ""

# Check if Tomcat is installed at default location
if [ -d "/opt/tomcat" ]; then
    echo "✓ Found Tomcat at /opt/tomcat"
    TOMCAT_HOME="/opt/tomcat"
elif [ -d "/usr/local/tomcat" ]; then
    echo "✓ Found Tomcat at /usr/local/tomcat"
    TOMCAT_HOME="/usr/local/tomcat"
else
    echo "⚠ Tomcat not found at standard locations"
    echo "  Searching for Tomcat installations..."
    find / -name "catalina.sh" 2>/dev/null | while read path; do
        echo "  Found: $path"
        TOMCAT_HOME=$(dirname $(dirname "$path"))
        echo "    TOMCAT_HOME: $TOMCAT_HOME"
    done
    exit 1
fi

echo ""
echo "Tomcat Directory Structure:"
echo "=========================================="
ls -la "$TOMCAT_HOME/" 2>/dev/null | grep -E "^d|webapps|bin|logs"

echo ""
echo "Tomcat Webapps Directory:"
echo "=========================================="
if [ -d "$TOMCAT_HOME/webapps" ]; then
    ls -lA "$TOMCAT_HOME/webapps/"
else
    echo "ERROR: webapps directory not found!"
    echo "Creating webapps directory..."
    mkdir -p "$TOMCAT_HOME/webapps"
    chmod 755 "$TOMCAT_HOME/webapps"
fi

echo ""
echo "Tomcat Process Status:"
echo "=========================================="
if ps aux | grep -v grep | grep "catalina\|tomcat"; then
    echo "✓ Tomcat is running"
    PID=$(ps aux | grep -v grep | grep catalina | awk '{print $2}' | head -1)
    echo "  PID: $PID"
else
    echo "✗ Tomcat is NOT running"
fi

echo ""
echo "Tomcat Port Status (8080):"
echo "=========================================="
if netstat -tulpn 2>/dev/null | grep ":8080"; then
    echo "✓ Port 8080 is listening"
else
    echo "✗ Port 8080 is NOT listening"
fi

echo ""
echo "Test Tomcat Connectivity:"
echo "=========================================="
if curl -s -m 3 "http://localhost:8080/" | head -5; then
    echo "✓ Tomcat is responding to HTTP requests"
else
    echo "✗ Tomcat is NOT responding to HTTP requests"
fi

echo ""
echo "Tomcat Logs (Last 20 lines):"
echo "=========================================="
if [ -f "$TOMCAT_HOME/logs/catalina.out" ]; then
    tail -20 "$TOMCAT_HOME/logs/catalina.out"
else
    echo "No catalina.out found"
fi

echo ""
echo "=========================================="
echo "ENVIRONMENT VARIABLES FOR JENKINS"
echo "=========================================="
echo "Set these in Jenkins environment:"
echo ""
echo "export TOMCAT_HOME=\"$TOMCAT_HOME\""
echo "export CATALINA_HOME=\"$TOMCAT_HOME\""
echo ""

echo "=========================================="
echo "DIAGNOSIS COMPLETE"
echo "=========================================="
