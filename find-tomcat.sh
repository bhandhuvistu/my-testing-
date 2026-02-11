#!/bin/bash
# Find Tomcat installation and export correct variables

echo "Finding Tomcat installation..."

TOMCAT_HOME=""

# Check common locations
for LOCATION in /opt/tomcat /usr/local/tomcat /home/ubuntu/tomcat /usr/share/tomcat /var/lib/tomcat; do
    if [ -f "$LOCATION/bin/catalina.sh" ]; then
        TOMCAT_HOME="$LOCATION"
        echo "✓ Found Tomcat at: $TOMCAT_HOME"
        break
    fi
done

# If not found, search filesystem
if [ -z "$TOMCAT_HOME" ]; then
    echo "Searching filesystem for Tomcat..."
    FOUND=$(find / -name "catalina.sh" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        TOMCAT_HOME=$(dirname $(dirname "$FOUND"))
        echo "✓ Found Tomcat at: $TOMCAT_HOME"
    fi
fi

if [ -z "$TOMCAT_HOME" ]; then
    echo "ERROR: Tomcat not found!"
    exit 1
fi

# Verify directory
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "Creating webapps directory..."
    mkdir -p "$TOMCAT_HOME/webapps"
fi

# Export variables
export TOMCAT_HOME
export CATALINA_HOME="$TOMCAT_HOME"

# Show summary
echo ""
echo "=========================================="
echo "Tomcat Configuration"
echo "=========================================="
echo "TOMCAT_HOME: $TOMCAT_HOME"
echo "CATALINA_HOME: $CATALINA_HOME"
echo "Webapps: $TOMCAT_HOME/webapps"
echo "Bin: $TOMCAT_HOME/bin"
echo "Logs: $TOMCAT_HOME/logs"
echo ""

# Test start/stop
echo "Testing Tomcat startup..."
"$TOMCAT_HOME/bin/startup.sh"
sleep 3

if curl -s http://localhost:8080/ > /dev/null; then
    echo "✓ Tomcat started successfully"
    "$TOMCAT_HOME/bin/shutdown.sh"
else
    echo "✗ Tomcat failed to start"
    tail -50 "$TOMCAT_HOME/logs/catalina.out"
    exit 1
fi

echo ""
echo "Add these to Jenkins global environment variables:"
echo "TOMCAT_HOME=$TOMCAT_HOME"
echo "CATALINA_HOME=$TOMCAT_HOME"
