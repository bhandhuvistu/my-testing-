# Jenkins Testing Job - How to Use

## 📋 What You Have Created

### 1. **Testing Pipeline Job** (`.jenkins/testing-job`)
   - Checks out code from GitHub
   - Builds the Maven project
   - Runs unit tests
   - Runs integration tests
   - Generates code coverage reports
   - Publishes test results
   - Archives artifacts

### 2. **Webhook Configuration** (`get-webhook-url.sh`)
   - Gets your Jenkins webhook URL
   - Tests webhook connectivity
   - Shows GitHub setup instructions

### 3. **Job Trigger Script** (`trigger-testing-job.sh`)
   - Manually trigger the testing job
   - Pass custom parameters (branch, test type, etc.)
   - Shows build results

### 4. **Documentation** (`JENKINS_TESTING_GUIDE.md`)
   - Complete setup instructions
   - GitHub webhook integration
   - Troubleshooting guide

---

## 🚀 Quick Start (2 Minutes)

### Step 1: Get Webhook URL
```bash
./get-webhook-url.sh
```

You'll see:
```
Webhook URL:
http://your-jenkins-url:8080/github-webhook/
```

### Step 2: Setup GitHub Webhook
1. Go to: https://github.com/bhandhuvistu/my-testing-/settings/hooks
2. Click "Add webhook"
3. Paste the webhook URL you got in Step 1
4. Set Content type to `application/json`
5. Click "Add webhook"

### Step 3: Create Jenkins Job
1. Jenkins Dashboard → **New Item**
2. Name: `testing-job`
3. Type: **Pipeline**
4. Under Pipeline:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/bhandhuvistu/my-testing-.git`
   - Branch: `*/main`
   - Script Path: `.jenkins/testing-job`
5. Click **Save**

### Step 4: Test It
```bash
./trigger-testing-job.sh
```

Done! 🎉

---

## 🔧 How It Works

### Automatic Testing (via GitHub Push)

```
1. You push code to GitHub
   git push origin main
   
2. GitHub sends webhook to Jenkins
   POST http://your-jenkins-url/github-webhook/
   
3. Jenkins receives webhook
   
4. Jenkins starts testing-job automatically
   
5. Tests run and results are published
   
6. You see results in Jenkins dashboard
```

### Manual Testing (via CLI)

```bash
# Simple trigger
./trigger-testing-job.sh

# With custom branch
./trigger-testing-job.sh http://localhost:8080 testing-job develop

# With all parameters
./trigger-testing-job.sh http://your-jenkins:8080 testing-job main all true
```

---

## 📊 Available Test Parameters

When triggering the job, you can pass:

| Parameter | Values | Default |
|---|---|---|
| `GIT_BRANCH` | any branch name | `main` |
| `TEST_TYPE` | `unit` / `integration` / `all` | `all` |
| `GENERATE_REPORT` | `true` / `false` | `true` |

### Example: Run only unit tests
```bash
./trigger-testing-job.sh http://localhost:8080 testing-job main unit true
```

---

## 📈 Viewing Results

### In Jenkins Dashboard

1. Go to: `http://your-jenkins-url/job/testing-job/`
2. Click the latest build number
3. See:
   - ✓ Test Result summary
   - ✓ Console output
   - ✓ Artifacts (test reports)
   - ✓ Build duration
   - ✓ Pass/fail count

### Via Command Line

```bash
# View console output
curl http://localhost:8080/job/testing-job/lastBuild/consoleText

# Get build status
curl http://localhost:8080/job/testing-job/lastBuild/api/json

# Download test reports
curl http://localhost:8080/job/testing-job/lastBuild/artifact/target/surefire-reports/
```

---

## 🔐 Webhook Security

For production, add a secret token:

1. GitHub Webhook Settings → Add "Secret"
2. Jenkins Configure System → GitHub section → Add token
3. Jenkins will validate signatures automatically

---

## 🆘 Troubleshooting

### Webhook not triggering jobs?

1. Check GitHub webhook deliveries:
   https://github.com/bhandhuvistu/my-testing-/settings/hooks

2. Test webhook manually:
   ```bash
   curl -X POST http://your-jenkins-url/github-webhook/
   ```

3. Check Jenkins logs:
   ```bash
   tail -f /var/log/jenkins/jenkins.log | grep -i webhook
   ```

### Tests not running?

1. Verify Job Exists:
   ```bash
   curl http://your-jenkins-url/job/testing-job/api/json
   ```

2. Check Credentials:
   - Jenkins Credentials needed for GitHub (if private repo)
   - Configure in Jenkins → Credentials

3. View Build Console:
   ```bash
   curl http://your-jenkins-url/job/testing-job/lastBuild/consoleText
   ```

### Can't find Jenkins URL?

Check:
1. Jenkins Dashboard → Manage Jenkins → Configure System → Jenkins Location
2. Or: Docker inspect if using container
3. Or: Check network with `netstat -tuln | grep 8080`

---

## 📚 Files Summary

```
.jenkins/
└── testing-job              ← Pipeline definition (imported by Jenkins)

Root directory:
├── get-webhook-url.sh       ← Get your webhook URL
├── trigger-testing-job.sh   ← Manually trigger tests
├── JENKINS_QUICK_START.sh   ← This overview
├── JENKINS_TESTING_GUIDE.md ← Complete setup guide
└── URL_PATHS.md             ← Find application URLs
```

---

## 💡 Pro Tips

### 1. Automated Testing on Every Push
```bash
# Just push code - tests run automatically
git add .
git commit -m "Update"
git push origin main
# Jenkins tests automatically!
```

### 2. Test Different Branches
```bash
./trigger-testing-job.sh http://localhost:8080 testing-job develop all false
# This tests the 'develop' branch
```

### 3. CI/CD Pipeline Flow
```
Build Job (compiles) → Testing Job (tests) → Deploy Job (deploys)
```

### 4. Branch Protection in GitHub
Enable "Require status checks to pass before merging":
- GitHub Repo → Settings → Branches
- Add rule for main branch
- Require "Jenkins" status check
- Now merges require tests to pass ✓

---

## 🎯 Next Steps

1. ✅ Copy webhook URL: `./get-webhook-url.sh`
2. ✅ Add webhook to GitHub
3. ✅ Create Jenkins job
4. ✅ Test with: `./trigger-testing-job.sh`
5. ✅ Push code to trigger tests automatically
6. ✅ View results: http://jenkins-url/job/testing-job/

---

## 📞 Need Help?

1. See **JENKINS_TESTING_GUIDE.md** for detailed setup
2. See **URL_PATHS.md** to find your Jenkins URL
3. Run `./JENKINS_QUICK_START.sh` for quick reference
4. Check Jenkins logs for detailed error messages

**For Jenkins URL help:**
```bash
echo "Check: http://localhost:8080"
# or
echo "Check: http://$(hostname -I | awk '{print $1}'):8080"
```
