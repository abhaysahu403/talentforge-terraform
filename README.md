# TalentForge Infrastructure - Automated Deployment

Complete AWS infrastructure automation for TalentForge application using Terraform and GitHub Actions.

## 🚀 Quick Start

### Deploy Entire Application (One Command)

```bash
terraform apply -auto-approve
```

**That's it!** Wait 15 minutes and your application is ready.

---

## 📋 What Gets Deployed

### Infrastructure (25 AWS Resources)
- ✅ VPC with public/private subnets
- ✅ Internet Gateway and Route Tables
- ✅ 3 Security Groups (Frontend, Backend, RDS)
- ✅ 2 EC2 instances (t2.micro) - Frontend & Backend
- ✅ RDS MySQL database (db.t3.micro)
- ✅ S3 bucket for file uploads
- ✅ IAM roles and instance profiles

### Application (Fully Configured)
- ✅ Frontend: React app with nginx reverse proxy
- ✅ Backend: Node.js API with environment variables
- ✅ Database: MySQL initialized with schema + seed data
- ✅ Docker: Pre-built images from Docker Hub
- ✅ Networking: All CORS and proxy configured

---

## 🎯 Deployment Methods

### Method 1: Local Terraform (Fast)

```bash
# One-time setup
terraform init

# Deploy everything
terraform apply

# Get access URLs
terraform output
```

### Method 2: GitHub Actions (Automated)

1. **Setup** (one-time): Add 4 secrets in GitHub repo settings
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DB_PASSWORD`
   - `JWT_SECRET`

2. **Deploy**: Just push to main branch
```bash
git push origin main
```

3. **Monitor**: Go to Actions tab and watch deployment

See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for detailed instructions.

---

## 📖 Documentation

- **[AUTOMATED_DEPLOYMENT.md](AUTOMATED_DEPLOYMENT.md)** - Complete automation guide with both deployment methods
- **[GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)** - Step-by-step GitHub Actions configuration
- **[AUTOMATION_PLAN.md](AUTOMATION_PLAN.md)** - Technical details of what's automated
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Original deployment guide (reference)
- **[QUICK_START.md](QUICK_START.md)** - 15-minute quick start guide

---

## 🔑 Access Information

After deployment completes:

### Application URL
```
http://<frontend-ip>
```

### Login Credentials
- **Email**: `admin@talentforge.com` ⚠️ (use email, not username)
- **Password**: `Password123`

### Database Access
```bash
mysql -h <rds-endpoint> -u admin -pTalentForge123! talentforge
```

### SSH Access
```bash
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>   # Frontend
ssh -i AbhayOrg.pem ubuntu@<backend-ip>    # Backend
```

---

## ✅ Verification

### Check Deployment Status

```bash
# Get outputs
terraform output

# Test frontend
curl http://<frontend-ip>/healthz

# Test backend
curl http://<backend-ip>:5000/health

# Test API proxy
curl http://<frontend-ip>/api/health
```

### Check User Data Progress

```bash
# Frontend logs
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
tail -f /var/log/userdata.log

# Backend logs
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
tail -f /var/log/userdata.log
```

---

## 🗂️ Project Structure

```
talentforge-terraform/
├── main.tf                          # Main infrastructure configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── provider.tf                      # AWS provider config
├── terraform.tfvars                 # Variable values
│
├── modules/
│   ├── vpc/                         # VPC and networking
│   ├── security-groups/             # Security group rules
│   ├── iam/                         # IAM roles and policies
│   ├── frontend-ec2/                # Frontend EC2 with automated setup
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── userdata-automated.sh    # Automated frontend deployment
│   ├── backend-ec2/                 # Backend EC2 with automated setup
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── userdata-automated.sh    # Automated backend deployment
│   ├── rds/                         # RDS MySQL database
│   └── s3/                          # S3 bucket for uploads
│
├── .github/workflows/
│   └── terraform-deploy.yml         # GitHub Actions CI/CD
│
└── docs/
    ├── AUTOMATED_DEPLOYMENT.md      # Main automation guide
    ├── GITHUB_ACTIONS_SETUP.md      # GitHub Actions setup
    ├── AUTOMATION_PLAN.md           # Technical details
    └── ...
```

---

## 🔧 Configuration

### Key Variables

Edit `terraform.tfvars` to customize:

```hcl
project_name = "talentforge"
aws_region   = "us-east-1"
db_password  = "TalentForge123!"      # Change for production
jwt_secret   = "your-secret-key"      # Change for production
```

### Docker Images Used

- **Frontend**: `abhaysahu403/talentforge-frontend:latest`
- **Backend**: `abhaysahu403/talentforge-backend:latest`

Pre-built images avoid memory issues on t2.micro instances.

---

## 🎨 Architecture

```
Internet
    ↓
Frontend EC2 (100.55.88.10:80)
    ├── nginx (reverse proxy)
    ├── React app
    └── /api/* → Backend EC2
        ↓
Backend EC2 (3.230.115.251:5000)
    ├── Node.js API
    ├── → RDS MySQL (private subnet)
    └── → S3 Bucket
```

### Key Features
- ✅ **Localhost Fix**: nginx `sub_filter` rewrites hardcoded URLs
- ✅ **Database Init**: Automatic schema and seed data import
- ✅ **Environment Variables**: All config injected at runtime
- ✅ **Dependencies**: Backend waits for RDS before starting
- ✅ **CORS**: Configured for cross-origin requests

---

## 🧪 Testing the Automation

### Fresh Deployment Test

```bash
# Destroy current infrastructure
terraform destroy -auto-approve

# Wait 5 minutes for cleanup

# Deploy fresh
terraform apply -auto-approve

# Wait 15 minutes for user data scripts

# Test login
open http://$(terraform output -raw frontend_public_ip)
# Login: admin@talentforge.com / Password123
```

---

## 💰 Cost Estimate

**Monthly cost (running 24/7)**:
- Frontend EC2 (t2.micro): ~$8
- Backend EC2 (t2.micro): ~$8
- RDS MySQL (db.t3.micro): ~$15
- S3 + Data transfer: ~$5
- **Total**: ~$36-40/month

**Save costs**:
```bash
# Stop instances when not in use
aws ec2 stop-instances --instance-ids <instance-id>

# Stop RDS
aws rds stop-db-instance --db-instance-identifier talentforge-mysql
```

---

## 🗑️ Cleanup

### Destroy Everything

```bash
terraform destroy -auto-approve
```

This removes:
- All EC2 instances
- RDS database (⚠️ data lost!)
- S3 bucket
- VPC and networking
- All IAM roles

---

## 🐛 Troubleshooting

### User Data Scripts Not Running

```bash
ssh -i AbhayOrg.pem ubuntu@<ec2-ip>
cat /var/log/userdata.log
cat /var/log/cloud-init-output.log
```

### Database Connection Failed

```bash
# Test RDS connection
mysql -h $(terraform output -raw rds_endpoint | cut -d: -f1) \
  -u admin -pTalentForge123! talentforge
```

### Frontend CORS Errors

```bash
# Check nginx config
ssh -i AbhayOrg.pem ubuntu@<frontend-ip>
sudo docker exec talentforge-frontend cat /etc/nginx/conf.d/default.conf | grep sub_filter
```

### Backend Container Issues

```bash
# Check logs
ssh -i AbhayOrg.pem ubuntu@<backend-ip>
sudo docker logs talentforge-backend --tail 50
```

---

## 📞 Support

### Documentation
- [AUTOMATED_DEPLOYMENT.md](AUTOMATED_DEPLOYMENT.md) - Full automation guide
- [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) - CI/CD setup

### Logs
- Frontend: `/var/log/userdata.log` on Frontend EC2
- Backend: `/var/log/userdata.log` on Backend EC2
- Docker: `docker logs <container-name>`

---

## ✨ Features

### What Makes This Special

1. **One-Command Deploy**: `terraform apply` does everything
2. **No Manual Steps**: User data scripts handle all configuration
3. **Pre-built Images**: No build failures on small instances
4. **Database Auto-Init**: Schema and seed data loaded automatically
5. **CORS/Proxy Fixed**: nginx sub_filter handles localhost issue
6. **GitHub Actions**: Optional CI/CD pipeline ready to use
7. **Idempotent**: Run `terraform apply` multiple times safely
8. **Clean Destroy**: `terraform destroy` removes everything

---

## 🎯 Quick Commands

```bash
# Deploy
terraform apply -auto-approve

# Get IPs
terraform output

# Check status
terraform show

# View state
terraform state list

# Refresh outputs
terraform refresh

# Destroy
terraform destroy -auto-approve

# Format code
terraform fmt -recursive

# Validate config
terraform validate
```

---

## 📝 Test Users

All users have password: `Password123`

- `admin@talentforge.com` - Administrator
- `hr@talentforge.com` - HR Manager
- `manager@talentforge.com` - Department Manager
- `alice@talentforge.com` - Employee
- `bob@talentforge.com` - Employee
- `carol@talentforge.com` - Employee

---

## 🚀 Next Steps After Deployment

1. ✅ Access frontend at http://\<frontend-ip\>
2. ✅ Login with admin@talentforge.com / Password123
3. ✅ Explore the application:
   - Dashboard
   - Employee management
   - Job postings
   - Applications
   - Leave requests
   - Documents
4. ✅ Test all features
5. ✅ When done, run `terraform destroy`

---

## 📄 License

This infrastructure code is part of the TalentForge project.

---

**Ready to deploy? Run `terraform apply` and watch the magic happen! 🎉**
