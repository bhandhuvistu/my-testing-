# Jenkins Job Configuration Guide

## Problem Identified

Your Jenkins build failed with:
```
/tmp/jenkins12232352010551269683.sh: 4: BUILD: not found
```

This happens when the shell script has syntax errors or is run with the wrong shell interpreter.

## Solutions

### Option 1: Use Simple Shell Commands (RECOMMENDED)

In Jenkins Job → Configure → Build → Execute Shell, use:

```bash
#!/bin/bash
set -e

echo "Building project..."
cd $WORKSPACE

# Build with Maven
if [ -f "pom.xml" ]; then
    mvn clean install -DskipTests
fi

echo "Build complete!"
```

### Option 2: Fix Script Shebang

Make sure your script starts with:
```bash
#!/bin/bash
```

NOT:
```bash
#!/bin/sh
```

### Option 3: Source a Script File

Instead of typing in Jenkins UI, create a script file and call it:

**In Jenkins Execute Shell:**
```bash
bash $WORKSPACE/jenkins-simple-build.sh
```

## Common Issues

| Issue | Solution |
|-------|----------|
| `command not found` | Use `set -x` to debug, check PATH |
| `/bin/sh: line X: ...: not found` | Use `#!/bin/bash` instead of `#!/bin/sh` |
| Variable not found | Quote variables: `"${VAR}"` |
| File not found | Use full path or `cd $WORKSPACE` first |
| Permission denied | Run `chmod +x script.sh` |

## Testing Script Locally

Before using in Jenkins, test locally:

```bash
# Test with sh
sh jenkins-simple-build.sh

# Test with bash
bash jenkins-simple-build.sh

# Test execution
./jenkins-simple-build.sh
```

## Environment Variables in Jenkins

When your script runs in Jenkins, these are available:
- `$WORKSPACE` - Job workspace directory
- `$JOB_NAME` - Job name
- `$BUILD_NUMBER` - Build number
- `$BUILD_ID` - Build ID
- `$GIT_COMMIT` - Git commit SHA
- `$GIT_BRANCH` - Git branch

## Debugging

Add these to your script for debugging:

```bash
#!/bin/bash
set -e  # Exit on error
set -x  # Print commands being executed

echo "Debug: WORKSPACE=$WORKSPACE"
echo "Debug: JOB_NAME=$JOB_NAME"
echo "Debug: BUILD_NUMBER=$BUILD_NUMBER"
```

## Example Jenkins Freestyle Job Setup

1. **Configure** → **Source Code Management**
   - Repository URL: `https://github.com/bhandhuvistu/my-testing-.git`
   - Branch: `master` or `main`

2. **Configure** → **Build**
   - Add Build Step → Execute Shell
   - Copy one of these scripts or write inline

3. **Configure** → **Post-build Actions**
   - Archive artifacts: `target/*.war`
   - Email notifications

## Example Working Script

```bash
#!/bin/bash
set -e

BUILD_DIR="${WORKSPACE}/target"
WAR_FILE="${BUILD_DIR}/app.war"

echo "=========================================="
echo "Build Job: ${JOB_NAME} #${BUILD_NUMBER}"
echo "=========================================="

cd "${WORKSPACE}"

# Build
echo "Running Maven build..."
mvn clean package -DskipTests

# Check if WAR was created
if [ -f "${WAR_FILE}" ]; then
    echo "Success! WAR created: ${WAR_FILE}"
else
    echo "Error: WAR file not found!"
    exit 1
fi

echo "=========================================="
echo "Build Completed!"
echo "=========================================="
```

## For Your Testing Job

Since your job is triggered by upstream project "Development", make sure:

1. Upstream project is configured and working
2. Build parameters pass correctly
3. Check Jenkins console output for the actual error

Use the `jenkins-simple-build.sh` script provided in your repo!
