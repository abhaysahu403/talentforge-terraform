# 🚀 Fully Automated Deployment Guide

This guide explains the **complete automation** that deploys TalentForge with a single command.

## ✅ What's Now Automated

Everything that was done manually is now automated in the user data scripts:

### Frontend EC2 (Automatic)
1. ✅ Install Docker
2. ✅ Pull pre-built image: `abhaysahu403/talentforge-frontend:latest`
3. ✅ Create nginx config with `sub_filter` fix for localhost issue
4. ✅ Start container on ports 80 and 3000
5. ✅ Deploy nginx configuration
6. ✅ Reload nginx

### Backend EC2 (Automatic)
1. ✅ Install Docker, Git, MySQL client
2. ✅ Pull pre-built image: `abhaysahu403/talentforge-backend:latest`
3. ✅ Clone database repository
4. ✅ Wait for RDS to be ready
5. ✅ Initialize database with schema.sql
6. ✅ Seed database with seed.sql
7. ✅ Start container with all environment variables:
   - DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
   - JWT_SECRET, CORS_ORIGIN
   - AWS_REGION, S3_BUCKET
   - PORT, NODE_ENV

### Infrastructure Dependencies
- Backend waits for RDS to be ready before initializing
- Frontend uses backend IP for API proxy
- All configuration is dynamic (no hardcoded IPs)

---

## 🎯 Deployment Options

You have **2 ways** to deploy:

### Option 1: Local Terraform (5 minutes)
### Option 2: GitHub Actions (One-Click Deploy)

---

## Option 1: Local Terraform Deployment

### Prerequisites
- Terraform installed
- AWS CLI configured with credentials
- SSH key pair created in AWS (AbhayOrg.pem)

### Steps

#### 1. Clone Repository
```bash
cd C:\Projects\Telentforge-software\Talentforge
cd talentforge-terraform
```

#### 2. Review Variables (Optional)
Check `terraform.tfvars` and `variables.tf` for default values:
- Project name: `talentforge`
- AWS Region: `us-east-1`
- DB Password: `TalentForge123!`
- JWT Secret: `my-super-secret-jwt-key-2026`

To change values, edit `terraform.tfvars`:
```hcl
project_name = "talentforge"
aws_region   = "us-east-1"
db_password  = "YourSecurePassword"
jwt_secret   = "your-jwt-secret-key"
```

#### 3. Initialize Terraform
```bash
terraform init
```

#### 4. Validate Configuration
```bash
terraform validate
```

#### 5. Preview Changes
```bash
terraform plan
```

Review the plan:
- 25 resources to be created
- VPC, subnets, EC2, RDS, S3, IAM, security groups

#### 6. Deploy Everything
```bash
terraform apply
```

Type `yes` when prompted.

**⏱️ Duration**: 
- Terraform: ~5 minutes
- User data scripts: ~8-10 minutes
- **Total**: ~15 minutes

#### 7. Get Outputs
```bash
terraform output
```

You'll see:
```
frontend_public_ip = "X.X.X.X"
backend_public_ip = "Y.Y.Y.Y"
rds_endpoint = "talentforge-mysql.xxxxx.us-east-1.rds.amazonaws.com:3306"
s3_bucket_name = "talentforge-uploads-bucket"
```

#### 8. Wait for User Data Scripts
The EC2 instances need time to run the automated setup:

**Check Frontend Progress**:
```bash
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
tail -f /var/log/userdata.log
```

**Check Backend Progress**:
```bash
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
tail -f /var/log/userdata.log
```

Look for:
- Frontend: "Frontend Setup Complete"
- Backend: "Backend Setup Complete"

#### 9. Test Deployment
```bash
# Test frontend
curl http://<frontend-ip>/healthz

# Test backend
curl http://<backend-ip>:5000/health

# Test API proxy
curl http://<frontend-ip>/api/health
```

#### 10. Access Application
Open browser: `http://<frontend-ip>`

**Login**:
- Email: `admin@talentforge.com`
- Password: `Password123`

---

## Option 2: GitHub Actions Deployment

### One-Time Setup

#### 1. Add GitHub Secrets
Go to your repository → Settings → Secrets and variables → Actions

Add these secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `DB_PASSWORD` - Database password (e.g., `TalentForge123!`)
- `JWT_SECRET` - JWT secret key (e.g., `my-super-secret-jwt-key-2026`)

#### 2. Commit and Push Changes
```bash
cd C:\Projects\Telentforge-software\Talentforge\talentforge-terraform
git add .
git commit -m "Add automated deployment with user data scripts"
git push origin main
```

### Deploy with GitHub Actions

#### Method 1: Automatic Deploy (Push to Main)
```bash
git push origin main
```

GitHub Actions will automatically:
1. Run `terraform plan` (on every PR/push)
2. Run `terraform apply` (only on push to main)
3. Display deployment info in the Actions summary

#### Method 2: Manual Deploy (Workflow Dispatch)
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Terraform Deploy" workflow
4. Click "Run workflow" → "Run workflow"
5. Monitor progress in real-time

#### View Deployment Results
After successful deployment:
1. Go to Actions tab
2. Click on the completed workflow
3. View the deployment summary with:
   - Frontend URL
   - Backend API URL
   - Login credentials
   - Infrastructure details

---

## 🔍 Verification Checklist

After deployment completes, verify:

### 1. Infrastructure Created
```bash
terraform show
```
Check for 25 resources created.

### 2. EC2 Instances Running
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=talentforge-*" --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]"
```

### 3. RDS Database Ready
```bash
aws rds describe-db-instances --db-instance-identifier talentforge-mysql --query "DBInstances[0].DBInstanceStatus"
```

### 4. Frontend Container Running
```bash
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
sudo docker ps | grep talentforge-frontend
```

### 5. Backend Container Running
```bash
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
sudo docker ps | grep talentforge-backend
```

### 6. Database Initialized
```bash
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
mysql -h <rds-endpoint> -u admin -pTalentForge123! talentforge -e "SHOW TABLES;"
```

Should show 8 tables:
- applications
- audit_logs
- departments
- documents
- employees
- jobs
- leave_requests
- users

### 7. Application Accessible
- Frontend: http://\<frontend-ip\>
- Backend Health: http://\<backend-ip\>:5000/health
- API Proxy: http://\<frontend-ip\>/api/health

### 8. Login Working
- Email: admin@talentforge.com
- Password: Password123
- Should redirect to dashboard after login

---

## 🎯 Success Indicators

You'll know deployment is successful when:

✅ Terraform outputs show all IPs and endpoints  
✅ User data logs show "Setup Complete" messages  
✅ Docker containers are running (docker ps)  
✅ Database has 8 tables with seed data  
✅ Frontend accessible on port 80  
✅ Backend API responds to /health  
✅ Login works without CORS errors  
✅ Dashboard loads after login  

---

## 🗑️ Cleanup (Destroy Everything)

### Option 1: Local Terraform
```bash
cd C:\Projects\Telentforge-software\Talentforge\talentforge-terraform
terraform destroy
```

Type `yes` to confirm.

### Option 2: GitHub Actions
1. Go to Actions tab
2. Select "Terraform Deploy" workflow
3. Click "Run workflow"
4. Select "Destroy" environment
5. Approve the destroy action

**⚠️ Warning**: This will delete:
- All EC2 instances
- RDS database (data lost!)
- S3 bucket contents
- VPC and networking
- All IAM roles and security groups

---

## 📊 Cost Estimate

Running 24/7:
- Frontend EC2 (t2.micro): ~$8/month
- Backend EC2 (t2.micro): ~$8/month
- RDS MySQL (db.t3.micro): ~$15/month
- S3 Storage: ~$0.50/month
- Data Transfer: ~$5/month

**Total**: ~$36-40/month

To save costs:
- Stop EC2 instances when not in use
- Stop RDS database (saves ~$15/month)
- Use AWS Free Tier if eligible

---

## 🔧 Troubleshooting

### Issue: User Data Scripts Not Running

**Check**:
```bash
ssh -i AbhayOrg.pem ubuntu@<ec2-ip>
cat /var/log/userdata.log
```

If empty, check:
```bash
cat /var/log/cloud-init-output.log
```

### Issue: Database Connection Failed

**Check RDS endpoint**:
```bash
terraform output rds_endpoint
```

**Test connection**:
```bash
mysql -h <rds-endpoint> -u admin -pTalentForge123! talentforge
```

### Issue: Frontend Shows CORS Errors

**Check nginx config**:
```bash
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
sudo docker exec talentforge-frontend cat /etc/nginx/conf.d/default.conf | grep sub_filter
```

Should show:
```
sub_filter 'http://localhost:5000/api' '/api';
```

### Issue: Backend Container Not Starting

**Check logs**:
```bash
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
sudo docker logs talentforge-backend
```

**Check environment variables**:
```bash
sudo docker inspect talentforge-backend | grep -A 20 Env
```

### Issue: Database Not Initialized

**Manually initialize**:
```bash
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
cd /home/ubuntu/talentforge-database
mysql -h <rds-endpoint> -u admin -pTalentForge123! talentforge < schema.sql
mysql -h <rds-endpoint> -u admin -pTalentForge123! talentforge < seed.sql
```

---

## 🎉 Summary

### What You Can Now Do

1. **Deploy from scratch**: `terraform apply`
2. **Deploy from GitHub**: Push to main or click "Run workflow"
3. **Everything works**: No manual configuration needed
4. **Destroy and redeploy**: `terraform destroy` then `terraform apply`

### What Happens Automatically

1. ✅ VPC, subnets, and networking created
2. ✅ Security groups configured
3. ✅ IAM roles assigned
4. ✅ RDS database created and initialized
5. ✅ S3 bucket created
6. ✅ Frontend EC2 deployed with nginx fix
7. ✅ Backend EC2 deployed with environment variables
8. ✅ Docker containers running
9. ✅ Application accessible and working

### Next Deployment

To deploy again:
```bash
terraform destroy  # Clean up
terraform apply    # Deploy fresh
# Wait 15 minutes
# Open http://<frontend-ip>
# Login and use!
```

**That's it!** 🚀

---

## 📞 Support

If you encounter issues:
1. Check `/var/log/userdata.log` on EC2 instances
2. Check `terraform output` for endpoints
3. Review this guide's troubleshooting section
4. Check GitHub Actions logs if using CI/CD

