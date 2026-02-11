# Jenkins Deployment with Tomcat9 (systemctl) Setup

## Your Setup

- **Tomcat Location:** `/var/lib/tomcat9`
- **Tomcat Service:** `tomcat9` (managed by systemctl)
- **Webapps:** `/var/lib/tomcat9/webapps`
- **Logs:** `/var/log/tomcat9/catalina.out`
- **Managed by:** `sudo systemctl start/stop tomcat9`

## Scripts Available

| Script | Purpose |
|--------|---------|
| `jenkins-build-deploy.sh` | Updated for tomcat9 |
| `deploy-tomcat9-systemctl.sh` | Complete deployment script |

---

## Setup Step 1: Configure Sudo Access (One-time)

For Jenkins to run `sudo systemctl` without password prompts:

1. **On Jenkins server**, edit sudoers:
```bash
sudo visudo
```

2. **Add these lines at the end:**
```bash
# Allow jenkins user to control tomcat9 without password
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl start tomcat9
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl stop tomcat9
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart tomcat9
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl status tomcat9
jenkins ALL=(ALL) NOPASSWD: /usr/bin/pkill -f tomcat9
jenkins ALL=(ALL) NOPASSWD: /usr/bin/pkill -9 -f tomcat9
jenkins ALL=(ALL) NOPASSWD: /bin/rm -f /var/lib/tomcat9/webapps/*.war
jenkins ALL=(ALL) NOPASSWD: /bin/rm -rf /var/lib/tomcat9/webapps/*
jenkins ALL=(ALL) NOPASSWD: /bin/cp *
jenkins ALL=(ALL) NOPASSWD: /bin/chmod *
```

3. **Save and exit** (Ctrl+X in nano, then Y, then Enter)

---

## Setup Step 2: Update Testing Job in Jenkins

1. **Jenkins** → **Testing** job → **Configure**

2. **Find Build section:**
   - **Clear existing Execute Shell**
   - **Add new Execute Shell:**

```bash
bash /home/ubuntu/my-testing-/deploy-tomcat9-systemctl.sh
```

3. **Or use this inline script:**

```bash
#!/bin/bash
set -e

WORKSPACE="/home/ubuntu/.jenkins/workspace/Testing"
WAR_FILE="$WORKSPACE/target/my-testing-app-1.0.0.war"
TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
APP_NAME="myweb"

echo "Stopping Tomcat..."
sudo systemctl stop tomcat9

echo "Removing old deployment..."
sudo rm -f $TOMCAT_WEBAPPS/$APP_NAME.war
sudo rm -rf $TOMCAT_WEBAPPS/$APP_NAME

echo "Deploying new application..."
sudo cp $WAR_FILE $TOMCAT_WEBAPPS/$APP_NAME.war
sudo chmod 644 $TOMCAT_WEBAPPS/$APP_NAME.war

echo "Starting Tomcat..."
sudo systemctl start tomcat9

echo "Waiting for application..."
sleep 5

curl http://localhost:8080/$APP_NAME/

echo "Deployment complete!"
```

4. **Remove Post-build Actions:**
   - Find **"Deploy war/ear to a container"**
   - Click **X** to delete it
   - Click **Save**

---

## Setup Step 3: Update Development Job (Optional)

If the Development job also needs to deploy:

1. **Jenkins** → **Development** job → **Configure**

2. **Add Build Step** → **Execute Shell:**

```bash
#!/bin/bash
set -e

# Build
mvn package

# Deploy to Tomcat9
TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
WAR=$(find $WORKSPACE/target -name "myweb*.war" | head -1)

echo "Deploying to Tomcat..."
sudo systemctl stop tomcat9
sleep 2

sudo rm -f $TOMCAT_WEBAPPS/myweb.war
sudo rm -rf $TOMCAT_WEBAPPS/myweb

sudo cp $WAR $TOMCAT_WEBAPPS/myweb.war
sudo chmod 644 $TOMCAT_WEBAPPS/myweb.war

sudo systemctl start tomcat9
sleep 5

curl http://localhost:8080/myweb/
```

---

## Test the Setup

### 1. Test Sudoers Configuration

Run on Jenkins server:

```bash
# Test as jenkins user
sudo -u jenkins sudo systemctl status tomcat9

# Should NOT ask for password
```

### 2. Test Script Manually

```bash
bash /home/ubuntu/my-testing-/deploy-tomcat9-systemctl.sh
```

### 3. Run Jenkins Job

**Jenkins** → **Testing** → **Build Now**

Should see:
```
✓ Build completed
✓ Tomcat stopped
✓ WAR deployed
✓ Tomcat started
✓ DEPLOYMENT SUCCESSFUL!
```

---

## Troubleshooting

### Issue: "sudo: no tty present and no askpass program specified"

**Solution:** Configure sudoers as shown above (Step 1)

### Issue: "Permission denied" when copying to /var/lib/tomcat9

**Solution:** Check file permissions:
```bash
ls -la /var/lib/tomcat9/webapps/
sudo chmod 755 /var/lib/tomcat9/webapps
```

### Issue: Tomcat won't start

**Check logs:**
```bash
sudo tail -100 /var/log/tomcat9/catalina.out
sudo systemctl status tomcat9
```

### Issue: Port 8080 already in use

**Find what's using it:**
```bash
netstat -tulpn | grep 8080
# Or
lsof -i :8080
```

**Kill the process:**
```bash
sudo systemctl stop tomcat9
sudo pkill -9 -f tomcat
sleep 2
sudo systemctl start tomcat9
```

---

## Verify Deployment

After running the job:

```bash
# Check if service is running
sudo systemctl status tomcat9

# Check if WAR is deployed
ls -la /var/lib/tomcat9/webapps/myweb*

# Test application
curl http://localhost:8080/myweb/

# View logs
sudo tail -50 /var/log/tomcat9/catalina.out
```

---

## Commands Reference

```bash
# Start Tomcat
sudo systemctl start tomcat9

# Stop Tomcat
sudo systemctl stop tomcat9

# Restart Tomcat
sudo systemctl restart tomcat9

# Check status
sudo systemctl status tomcat9

# View logs in real-time
sudo tail -f /var/log/tomcat9/catalina.out

# View last 100 lines
sudo tail -100 /var/log/tomcat9/catalina.out

# Check deployed apps
ls -la /var/lib/tomcat9/webapps/

# Check port
netstat -tulpn | grep 8080
or
lsof -i :8080
```

---

## Summary

**Quick Setup:**

1. ✅ Configure sudoers (one-time)
2. ✅ Update Testing job to use `deploy-tomcat9-systemctl.sh`
3. ✅ Remove "Deploy war/ear" post-build action
4. ✅ Run Development job → triggers Testing job
5. ✅ Artifact deployed from Dev → Testing

**Files:**
- `deploy-tomcat9-systemctl.sh` - Main deployment script
- `jenkins-build-deploy.sh` - Updated version

**Test:**
```bash
bash /home/ubuntu/my-testing-/deploy-tomcat9-systemctl.sh
```

Should complete successfully! 🚀
