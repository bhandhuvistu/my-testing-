# Fix: Tomcat Webapps Directory Not Found

## Error
```
cp: cannot create regular file '/opt/tomcat/webapps/myweb.war': No such file or directory
```

## Root Cause

The deployment script assumes Tomcat is at `/opt/tomcat`, but either:
1. Tomcat is installed at a different location
2. Jenkins doesn't have TOMCAT_HOME environment variable set
3. The webapps directory doesn't exist

## Solution 1: Find Tomcat Installation (Recommended)

Run on Jenkins server:

```bash
bash /home/ubuntu/my-testing-/diagnose-tomcat.sh
```

This will:
- ✓ Find Tomcat installation location
- ✓ Check status
- ✓ Show logs
- ✓ Export correct variables

Note the TOMCAT_HOME value from output.

---

## Solution 2: Configure Jenkins Global Environment Variables

1. **Jenkins Dashboard** → **Manage Jenkins** → **Configure System**
2. Scroll to **Global properties** section
3. Check **"Environment variables"**
4. Add new variables:
   - **Name:** `TOMCAT_HOME`
   - **Value:** (use actual Tomcat path from diagnose script)
   
   Example values:
   - `/opt/tomcat`
   - `/usr/local/tomcat`
   - `/home/ubuntu/tomcat`

5. **Add another variable:**
   - **Name:** `CATALINA_HOME`
   - **Value:** (same as TOMCAT_HOME)

6. Click **Save**

---

## Solution 3: Updated Deployment Script

The `jenkins-build-deploy.sh` has been updated to:

1. Check if TOMCAT_HOME directory exists
2. Check if webapps directory exists (create if needed)
3. Force kill Tomcat if shutdown doesn't work
4. Verify WAR file was copied successfully
5. Better error messages

Updated script is in: `jenkins-build-deploy.sh`

---

## Solution 4: Manual Fix on Jenkins Server

```bash
# 1. Find Tomcat
find / -name "catalina.sh" 2>/dev/null

# 2. Verify webapps exists
TOMCAT_HOME="/opt/tomcat"  # or actual location
ls -la "$TOMCAT_HOME/webapps" || mkdir -p "$TOMCAT_HOME/webapps"

# 3. Fix permissions
chmod 755 "$TOMCAT_HOME/webapps"
chmod 755 "$TOMCAT_HOME"

# 4. Test Tomcat
$TOMCAT_HOME/bin/startup.sh
sleep 3
curl http://localhost:8080/
$TOMCAT_HOME/bin/shutdown.sh
```

---

## Solution 5: Set Environment in Testing Job

Instead of global variables, set in the specific job:

1. **Jenkins** → **Testing** job → **Configure**
2. Go to **Build Environment** section
3. Check **"Set environment variables"** (if available)
4. Add: `TOMCAT_HOME` = actual path
5. Or, add Execute Shell before build:

```bash
export TOMCAT_HOME="/opt/tomcat"
export CATALINA_HOME="$TOMCAT_HOME"

# Verify
echo "TOMCAT_HOME: $TOMCAT_HOME"
ls -la "$TOMCAT_HOME/webapps"
```

---

## Diagnosis Steps

### Step 1: Run Diagnostic Script

```bash
bash /home/ubuntu/my-testing-/diagnose-tomcat.sh
```

### Step 2: Check Output

The script will show:
- ✓ Tomcat location
- ✓ Directory structure
- ✓ Process status
- ✓ Port 8080 status
- ✓ HTTP connectivity
- ✓ Recent logs

### Step 3: Identify the Issue

```bash
# If Tomcat is not running:
/opt/tomcat/bin/startup.sh

# If webapps directory missing:
mkdir -p /opt/tomcat/webapps

# If different Tomcat location, update scripts:
# Edit jenkins-build-deploy.sh and set TOMCAT_HOME
```

---

## Quick Fix (3 Steps)

1. **Run diagnostic:**
   ```bash
   bash /home/ubuntu/my-testing-/diagnose-tomcat.sh
   ```

2. **Note the TOMCAT_HOME value** (e.g., `/opt/tomcat` or `/usr/local/tomcat`)

3. **Update Jenkins:**
   - **Jenkins** → **Manage Jenkins** → **Configure System**
   - Add global variable: `TOMCAT_HOME` = the value from step 2
   - Click **Save**

4. **Run Testing job again**

---

## Scripts Available

| Script | Purpose |
|--------|---------|
| `diagnose-tomcat.sh` | Find and diagnose Tomcat issues |
| `find-tomcat.sh` | Find Tomcat and export variables |
| `jenkins-build-deploy.sh` | (Updated) Build and deploy with better error handling |

---

## Common Tomcat Locations

| Path | System |
|------|--------|
| `/opt/tomcat` | Manual installation |
| `/usr/local/tomcat` | Docker, manual install |
| `/usr/share/tomcat` | Package manager (apt/yum) |
| `/var/lib/tomcat` | Package manager alternate |
| `/home/ubuntu/tomcat` | Home directory installation |

---

## Verification Commands

```bash
# What version is running?
curl http://localhost:8080/

# Check running process
ps aux | grep tomcat

# Check listening port
netstat -tulpn | grep 8080

# View latest log
tail -50 /opt/tomcat/logs/catalina.out

# Check webapps directory
ls -la /opt/tomcat/webapps/
```

---

## Next Steps

1. **Identify TOMCAT_HOME:**
   ```bash
   bash diagnose-tomcat.sh
   ```

2. **Set in Jenkins:**
   - Jenkins → Manage Jenkins → Configure System
   - Add `TOMCAT_HOME` environment variable
   - Save

3. **Run Testing job again**
   - Development job #10 will trigger Testing job #11
   - Build should now succeed

4. **If still fails, check logs:**
   ```bash
   tail -100 $TOMCAT_HOME/logs/catalina.out
   ```

---

## For Development Job → Testing Job Pipeline

**Development Job:**
- Builds from github.com/bhandhuvistu/my-app.git
- Creates artifact
- Deploys to Tomcat
- Triggers Testing Job

**Testing Job:**
- Receives artifact from Development
- Uses deployment script
- Verifies deployment
- Test completes

Both need proper TOMCAT_HOME configuration!
