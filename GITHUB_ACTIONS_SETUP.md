# GitHub Actions Setup Guide

## Quick Setup for Automated Deployment

Follow these steps to enable one-click deployment from GitHub.

---

## Step 1: Add GitHub Secrets

### 1. Go to Repository Settings
1. Open your GitHub repository
2. Click **Settings** (top right)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2. Add Required Secrets

Add these 4 secrets:

#### Secret 1: AWS_ACCESS_KEY_ID
- **Name**: `AWS_ACCESS_KEY_ID`
- **Value**: Your AWS access key (e.g., `AKIAIOSFODNN7EXAMPLE`)
- Click **Add secret**

#### Secret 2: AWS_SECRET_ACCESS_KEY
- **Name**: `AWS_SECRET_ACCESS_KEY`
- **Value**: Your AWS secret key (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
- Click **Add secret**

#### Secret 3: DB_PASSWORD
- **Name**: `DB_PASSWORD`
- **Value**: `TalentForge123!`
- Click **Add secret**

#### Secret 4: JWT_SECRET
- **Name**: `JWT_SECRET`
- **Value**: `my-super-secret-jwt-key-2026`
- Click **Add secret**

---

## Step 2: Get AWS Credentials

If you don't have AWS credentials:

### Option 1: Use Existing IAM User
```bash
aws configure
# Your credentials are in:
# - Windows: C:\Users\<username>\.aws\credentials
# - Linux/Mac: ~/.aws/credentials
```

### Option 2: Create New IAM User

1. Go to AWS Console → IAM → Users
2. Click **Create user**
3. User name: `github-actions-terraform`
4. Click **Next**
5. Select **Attach policies directly**
6. Add these policies:
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonS3FullAccess`
   - `IAMFullAccess`
   - `AmazonVPCFullAccess`
7. Click **Next** → **Create user**
8. Go to the user → **Security credentials** tab
9. Click **Create access key**
10. Choose **Other**
11. Click **Create access key**
12. **Save the Access Key ID and Secret Access Key** (you won't see them again!)

---

## Step 3: Commit and Push Code

### 1. Commit Automation Files
```bash
cd C:\Projects\Telentforge-software\Talentforge\talentforge-terraform

git add .
git commit -m "Add automated deployment with GitHub Actions"
git push origin main
```

### 2. Verify Workflow File
The workflow file should be at:
```
.github/workflows/terraform-deploy.yml
```

---

## Step 4: Deploy with GitHub Actions

### Method 1: Automatic (Push to Main)

Every time you push to `main` branch:
1. **Terraform Plan** runs automatically
2. **Terraform Apply** runs automatically (creates infrastructure)

```bash
git push origin main
```

### Method 2: Manual (Workflow Dispatch)

1. Go to GitHub repository
2. Click **Actions** tab
3. Click **Terraform Deploy** workflow (left sidebar)
4. Click **Run workflow** button (right side)
5. Select branch: `main`
6. Click **Run workflow**

---

## Step 5: Monitor Deployment

### View Progress
1. Go to **Actions** tab
2. Click on the running workflow
3. Click on the job (e.g., "terraform-apply")
4. Watch the logs in real-time

### View Results
After completion, scroll to the bottom to see:
- Frontend URL: http://X.X.X.X
- Backend API: http://Y.Y.Y.Y:5000
- Login credentials
- Infrastructure summary

---

## Step 6: Access Your Application

### Wait for Completion
- **Terraform**: ~5 minutes
- **User data scripts**: ~10 minutes
- **Total**: ~15 minutes

### Check Deployment Status

#### Option 1: GitHub Actions Summary
- Go to Actions tab → Click completed workflow
- View the deployment summary

#### Option 2: SSH to EC2
```bash
# Get IPs from GitHub Actions output or:
terraform output

# Check frontend
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
tail -f /var/log/userdata.log

# Check backend
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
tail -f /var/log/userdata.log
```

### Test Application
```bash
# Frontend health
curl http://<frontend-ip>/healthz

# Backend health
curl http://<backend-ip>:5000/health
```

### Login
Open: `http://<frontend-ip>`

- **Email**: `admin@talentforge.com`
- **Password**: `Password123`

---

## GitHub Actions Workflow Explanation

### On Pull Request:
- ✅ Run `terraform plan` (preview changes)
- ❌ Does NOT apply changes

### On Push to Main:
- ✅ Run `terraform plan`
- ✅ Run `terraform apply` (creates infrastructure)
- ✅ Show deployment info

### On Manual Trigger:
- ✅ Run plan and apply
- ✅ Can also run destroy (with approval)

---

## Destroy Infrastructure via GitHub Actions

### Setup Destroy Environment (One-Time)

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `destroy`
4. Enable **Required reviewers**
5. Add yourself as a reviewer
6. Click **Save protection rules**

### Trigger Destroy

1. Go to **Actions** tab
2. Click **Terraform Deploy** workflow
3. Click **Run workflow**
4. The destroy job will wait for your approval
5. Go to the workflow run
6. Click **Review deployments**
7. Check `destroy`
8. Click **Approve and deploy**

⚠️ **Warning**: This will delete all AWS resources!

---

## Troubleshooting

### Issue: Workflow Fails at "Terraform Apply"

**Check**:
- AWS credentials are correct
- Secrets are properly set
- AWS IAM user has required permissions

**Fix**:
```bash
# Verify secrets are set
# Go to Settings → Secrets and variables → Actions
# Ensure all 4 secrets exist:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - DB_PASSWORD
# - JWT_SECRET
```

### Issue: "Error: Error acquiring the state lock"

**Reason**: Another terraform operation is running

**Fix**:
- Wait for other workflows to complete
- Or manually remove the lock:
```bash
terraform force-unlock <LOCK_ID>
```

### Issue: Workflow Runs But Infrastructure Not Created

**Check**:
1. Go to Actions → Failed workflow → View logs
2. Look for error messages in terraform apply step
3. Common issues:
   - AWS credentials invalid
   - IAM permissions insufficient
   - Resource limits exceeded

**Fix**:
- Update AWS credentials
- Add required IAM permissions
- Check AWS service quotas

### Issue: Can't See Deployment Info

**Check**:
1. Go to Actions tab
2. Click completed workflow
3. Scroll to bottom of page
4. Look for "🚀 Deployment Successful" section

If not visible:
- Check if terraform apply succeeded
- View raw logs for output values

---

## Cost Management

### Automatic Shutdown (Optional)

Add another workflow to stop instances at night:

`.github/workflows/stop-instances.yml`:
```yaml
name: Stop Instances

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily

jobs:
  stop:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Stop EC2 Instances
        run: |
          aws ec2 stop-instances --instance-ids \
            $(aws ec2 describe-instances \
              --filters "Name=tag:Name,Values=talentforge-*" \
              --query "Reservations[].Instances[?State.Name=='running'].InstanceId" \
              --output text)

      - name: Stop RDS Instance
        run: |
          aws rds stop-db-instance --db-instance-identifier talentforge-mysql
```

---

## Summary

### One-Time Setup:
1. ✅ Add 4 GitHub secrets
2. ✅ Push code to main branch

### Every Deployment:
1. ✅ Push to main OR click "Run workflow"
2. ✅ Wait 15 minutes
3. ✅ Access application

### To Destroy:
1. ✅ Trigger workflow with destroy option
2. ✅ Approve destruction

**That's it! Full automation! 🚀**

---

## Next Steps

1. ✅ Complete the secret setup above
2. ✅ Push your code
3. ✅ Watch the magic happen in Actions tab
4. ✅ Access your deployed application

No more manual steps needed! 🎉

