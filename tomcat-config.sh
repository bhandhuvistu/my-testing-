# Tomcat Deployment Configuration
# For use with Java 17 and Tomcat 10.x

# Tomcat Installation Path
TOMCAT_HOME=${TOMCAT_HOME:-/opt/tomcat}

# Application Configuration
APP_NAME=my-testing-app
APP_CONTEXT_PATH=/my-app

# Java Configuration for Java 17
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Tomcat Server Configuration
TOMCAT_PORT=8080
SHUTDOWN_PORT=8005
SHUTDOWN_COMMAND=SHUTDOWN

# Deployment Configuration
WAR_LOCATION=target
WAR_FILENAME=my-testing-app-*.war
BACKUP_DIR=${TOMCAT_HOME}/webapps/backup

# Deployment Timeout (seconds)
DEPLOY_TIMEOUT=30
STARTUP_TIMEOUT=60

# Health Check Configuration
HEALTH_CHECK_URL=http://localhost:${TOMCAT_PORT}${APP_CONTEXT_PATH}/
HEALTH_CHECK_INTERVAL=5
HEALTH_CHECK_RETRIES=12

# Logging
LOG_DIR=${TOMCAT_HOME}/logs
APP_LOG=${LOG_DIR}/${APP_NAME}.log

# Email Notification (optional)
NOTIFY_EMAIL=${NOTIFY_EMAIL:-}
NOTIFY_ON_FAILURE=${NOTIFY_ON_FAILURE:-false}
