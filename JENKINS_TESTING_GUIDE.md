# Jenkins Git Webhook Integration Guide

## Quick Setup - 5 Steps

### Step 1: Get Your Jenkins Webhook URL
```
Webhook URL Format:
https://your-jenkins-url/github-webhook/

Examples:
https://jenkins.example.com/github-webhook/
http://jenkins.local:8080/github-webhook/
http://192.168.1.100:8080/github-webhook/
```

### Step 2: Get Your Jenkins URL
Find it in Jenkins Dashboard:
- Jenkins → Configure System → Jenkins URL
- Or check your browser address bar

### Step 3: Configure GitHub Webhook

**Method A: Via GitHub Settings (Recommended)**

1. Go to your GitHub repo: https://github.com/bhandhuvistu/my-testing-
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Fill in:
   - **Payload URL**: `https://your-jenkins-url/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select "Push events" and "Pull requests"
4. Click **Add webhook**

**Method B: Via GitHub CLI**
```bash
gh repo edit bhandhuvistu/my-testing- \
  --add-topic "jenkins" \
  --add-topic "cicd"
```

### Step 4: Configure Jenkins Pipeline Job

1. Jenkins Dashboard → **New Item**
2. Enter Job Name: `my-testing-app-testing`
3. Select: **Pipeline**
4. Configure:
   - **Build Triggers**: 
     - ☑ GitHub hook trigger for GITScm polling
   - **Pipeline section**:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: `https://github.com/bhandhuvistu/my-testing-.git`
     - Branch: `*/main`
     - Script Path: `.jenkins/testing-job`

### Step 5: Test the Webhook

```bash
# Trigger manually from command line
curl -X POST https://your-jenkins-url/github-webhook/

# Or push to GitHub to trigger automatically
git push origin main
```

---

## Complete Webhook Details

### Webhook URL Components

```
Jenkins Dashboard → Manage Jenkins → Configure System → Jenkins URL

Default Ports:
- HTTP:  8080
- HTTPS: 8443
```

### Finding Your Exact URL

**Option 1: From Jenkins UI**
```
Manage Jenkins → Configure System → Jenkins Location
Look for "Jenkins URL" field
```

**Option 2: From Command Line** (if SSH access)
```bash
ssh user@jenkins-server
grep -r "jenkinsUrl" /var/lib/jenkins/

# Or check system variables
env | grep JENKINS
```

**Option 3: From Docker Container**
```bash
docker inspect jenkins-container | grep JENKINS_URL
# Or check logs
docker logs jenkins-container | grep "Jenkins URL"
```

### Complete Webhook Setup Example

**Jenkins URL**: `http://192.168.1.100:8080`
**Webhook**: `http://192.168.1.100:8080/github-webhook/`

GitHub Webhook Settings:
- Payload URL: `http://192.168.1.100:8080/github-webhook/`
- Content type: `application/json`
- Active: ✓ Checked
- Events: Push events, Pull requests

---

## Jenkins Pipeline Testing Job Setup

### Create Testing Pipeline Job

1. **New Item** → Name: `testing-job`
2. **Pipeline** job type
3. **Pipeline Definition**: 
   ```
   Pipeline script from SCM
   ```
4. **SCM Settings**:
   ```
   Repository: https://github.com/bhandhuvistu/my-testing-.git
   Branch: */main
   Script Path: .jenkins/testing-job
   ```

### Manually Trigger Job

```bash
curl -X POST \
  http://your-jenkins-url:8080/job/testing-job/build \
  -u username:password
```

### Add Parameters to Job

**Via Jenkins UI**:
1. Job Config → Build with Parameters
2. Add:
   - String: `GIT_BRANCH` (default: main)
   - Choice: `TEST_TYPE` (unit/integration/all)
   - Boolean: `GENERATE_REPORT` (default: true)

---

## Test Execution Options

### Option 1: Via Jenkins Dashboard

1. Go to `testing-job`
2. Click "Build with Parameters"
3. Select:
   - GIT_BRANCH: `main`
   - TEST_TYPE: `all`
   - GENERATE_REPORT: ✓
4. Click "Build"

### Option 2: Via GitHub Push

```bash
git push origin main
# Automatically triggers webhook → Jenkins job
```

### Option 3: Via API

```bash
# Run with default parameters
curl -X POST \
  http://jenkins-url:8080/job/testing-job/build

# Run with custom parameters
curl -X POST \
  http://jenkins-url:8080/job/testing-job/buildWithParameters \
  -d "GIT_BRANCH=main&TEST_TYPE=all&GENERATE_REPORT=true"
```

### Option 4: Via Jenkins CLI

```bash
# Install Jenkins CLI
java -jar jenkins-cli.jar -s http://jenkins-url:8080 \
  help build

# Trigger job
java -jar jenkins-cli.jar -s http://jenkins-url:8080 \
  build testing-job -p GIT_BRANCH=main -p TEST_TYPE=all
```

---

## Webhook Testing

### Verify Webhook is Configured

**From GitHub**:
1. Settings → Webhooks
2. See recent deliveries
3. Check HTTP status (200 = success)

**From Jenkins**:
```bash
# Check Jenkins logs
tail -f /var/log/jenkins/jenkins.log | grep -i github

# Or via Docker
docker logs jenkins | grep -i webhook
```

### Manual Webhook Test

```bash
# Send test payload to Jenkins
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"repository":{"url":"https://github.com/bhandhuvistu/my-testing-"}}' \
  http://your-jenkins-url/github-webhook/
```

### Troubleshooting Webhook

**Jenkins can't reach GitHub**:
```bash
# From Jenkins server
curl -v https://github.com/bhandhuvistu/my-testing-
```

**GitHub can't reach Jenkins**:
```bash
# From local machine
curl -v http://your-jenkins-url/github-webhook/
```

**Firewall Issues**:
```bash
# Check if port 8080 is accessible
netstat -tuln | grep 8080
# or
ss -tuln | grep 8080
```

---

## Testing Job Workflow

```
1. Git Webhook Triggered (push to main)
   ↓
2. Jenkins Receives Webhook
   ↓
3. Testing Job Starts Automatically
   ↓
4. Checkout Code from GitHub
   ↓
5. Build Project
   ↓
6. Run Unit Tests
   ↓
7. Run Integration Tests
   ↓
8. Generate Coverage Reports
   ↓
9. Archive Test Results
   ↓
10. Publishing Test Report
   ↓
11. Job Complete (Success/Failure)
```

---

## Test Results Access

### View Test Reports in Jenkins

1. Job Dashboard → "Test Result" tab
2. See:
   - Total tests run
   - Pass/Fail count
   - Test duration
   - Failed test details

### Download Test Artifacts

```bash
# From Jenkins server
curl -O http://jenkins-url:8080/job/testing-job/lastBuild/artifact/target/surefire-reports/
```

### Access Coverage Reports

```
Jenkins Job → Build → Artifacts
→ jacoco-report/index.html
```

---

## Best Practices

1. **Branch Protection**: Require tests pass before merge
   - GitHub Settings → Branches → Add rule
   - Require status checks to pass

2. **Notifications**:
   - Email on test failure
   - Slack webhook integration
   - GitHub checks status

3. **Test Optimization**:
   - Run unit tests first (fast)
   - Run integration tests (slower)
   - Cache dependencies

4. **Security**:
   - Use webhooks secret token
   - Restrict Jenkins URLs to whitelist IPs
   - Use credentials for authentication

---

## Quick Reference Commands

```bash
# Test webhook URL
curl -X POST http://jenkins-url:8080/github-webhook/

# Trigger job
curl -X POST http://jenkins-url:8080/job/testing-job/build

# Get job status
curl http://jenkins-url:8080/job/testing-job/api/json

# Download test results
curl http://jenkins-url:8080/job/testing-job/lastBuild/artifact/target/surefire-reports/

# View live logs
curl http://jenkins-url:8080/job/testing-job/lastBuild/consoleText
```
