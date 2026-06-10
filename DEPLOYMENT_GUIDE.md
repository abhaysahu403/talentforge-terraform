# TalentForge AWS Deployment Guide

## ✅ Current Status

1. **Terraform Configuration**: Fixed and validated
2. **Module Paths**: Corrected to `./modules/*`
3. **Plan Status**: Successfully generated (25 resources to create)
4. **Docker Images**: Built and pushed to Docker Hub

## 📋 Pre-Deployment Checklist

### 1. AWS Prerequisites
- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] EC2 Key Pair "AbhayOrg" exists in us-east-1 region
- [ ] AWS credentials configured (run `aws configure`)

### 2. Verify Key Pair
```bash
aws ec2 describe-key-pairs --key-names AbhayOrg --region us-east-1
```
If it doesn't exist, create it:
```bash
aws ec2 create-key-pair --key-name AbhayOrg --region us-east-1 --query 'KeyMaterial' --output text > AbhayOrg.pem
chmod 400 AbhayOrg.pem
```

### 3. Generate Secrets
```bash
# Generate JWT Secret (32 characters)
openssl rand -base64 32

# Generate DB Password (16 characters)
openssl rand -base64 16
```
**Save these values - you'll need them later!**

---

## 🚀 Deployment Steps

### Step 1: Deploy Infrastructure with Terraform

From the `talentforge-terraform` directory:

```bash
# Already completed:
# terraform init
# terraform validate
# terraform plan

# Apply the infrastructure
terraform apply
```

Type `yes` when prompted to create resources.

**Wait 5-10 minutes for resources to be created.**

### Step 2: Capture Output Values

After `terraform apply` completes, save these outputs:

```bash
terraform output > deployment-outputs.txt
```

You'll get:
- `frontend_public_ip` - Frontend EC2 IP
- `backend_public_ip` - Backend EC2 IP
- `rds_endpoint` - RDS MySQL endpoint
- `bucket_name` - S3 bucket name

**Example:**
```
frontend_public_ip = "3.80.123.45"
backend_public_ip = "3.80.234.56"
rds_endpoint = "talentforge-mysql.xxxxxxxxx.us-east-1.rds.amazonaws.com:3306"
bucket_name = "talentforge-uploads-bucket"
```

### Step 3: Wait for EC2 User Data Completion

The EC2 instances will automatically:
1. Install Docker and Git
2. Clone the repositories
3. Build Docker images
4. Run containers

**Check status:**
```bash
# SSH into Frontend EC2
ssh -i AbhayOrg.pem ubuntu@<FRONTEND_IP>
tail -f /var/log/userdata.log

# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@<BACKEND_IP>
tail -f /var/log/userdata.log
```

Wait until you see "Setup Complete" messages.

### Step 4: Initialize RDS Database

SSH into Backend EC2:
```bash
ssh -i AbhayOrg.pem ubuntu@<BACKEND_IP>
```

Install MySQL client and initialize database:
```bash
sudo apt update
sudo apt install mysql-client -y

# Connect to RDS
mysql -h <RDS_ENDPOINT_WITHOUT_PORT> -u admin -p

# Enter the default password (check RDS module for default password)
# Or set a new password if using AWS Secrets Manager
```

Then run the schema and seed files from the talentforge-database repository:
```bash
# Clone database repo
git clone https://github.com/abhaysahu403/talentforge-database.git
cd talentforge-database

# Initialize database
mysql -h <RDS_ENDPOINT_WITHOUT_PORT> -u admin -p talentforge < schema.sql
mysql -h <RDS_ENDPOINT_WITHOUT_PORT> -u admin -p talentforge < seed.sql
```

### Step 5: Update Backend Environment Variables

The backend needs to connect to RDS. Update the backend container with correct environment variables:

```bash
# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@<BACKEND_IP>

# Stop and remove existing container
docker stop talentforge-backend
docker rm talentforge-backend

# Run with correct environment variables
docker run -d \
  --name talentforge-backend \
  -p 5000:5000 \
  -e DB_HOST=<RDS_ENDPOINT_WITHOUT_PORT> \
  -e DB_PORT=3306 \
  -e DB_USER=admin \
  -e DB_PASSWORD=<YOUR_DB_PASSWORD> \
  -e DB_NAME=talentforge \
  -e JWT_SECRET=<YOUR_JWT_SECRET> \
  -e CORS_ORIGIN=http://<FRONTEND_IP> \
  -e AWS_REGION=us-east-1 \
  -e S3_BUCKET=talentforge-uploads-bucket \
  --restart always \
  abhaysahu403/talentforge-backend:latest
```

### Step 6: Update Frontend Environment Variables

The frontend needs to know the backend API URL:

```bash
# SSH into Frontend EC2
ssh -i AbhayOrg.pem ubuntu@<FRONTEND_IP>

# Stop and remove existing container
docker stop talentforge-frontend
docker rm talentforge-frontend

# Rebuild with correct API URL
cd talentforge-frontend
echo "REACT_APP_API_URL=http://<BACKEND_IP>:5000/api" > .env

# Rebuild and run
docker build -t talentforge-frontend .
docker run -d \
  --name talentforge-frontend \
  -p 3000:3000 \
  --restart always \
  talentforge-frontend
```

---

## 🧪 Testing the Deployment

### 1. Test Frontend
```bash
# Open in browser
http://<FRONTEND_IP>:3000
```

### 2. Test Backend API
```bash
# Health check
curl http://<BACKEND_IP>:5000/health

# Login endpoint
curl -X POST http://<BACKEND_IP>:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Password123"}'
```

### 3. Test Full Flow
1. Open frontend in browser
2. Login with credentials from seed data
3. Navigate through the application
4. Verify all features work

---

## 🔐 Configure GitHub Secrets (For CI/CD)

Add these secrets to each repository:

### All Repositories (Frontend, Backend, Terraform):
```
AWS_ACCESS_KEY_ID=<your_aws_access_key>
AWS_SECRET_ACCESS_KEY=<your_aws_secret_key>
AWS_REGION=us-east-1
DOCKERHUB_USERNAME=abhaysahu403
DOCKERHUB_TOKEN=<your_dockerhub_token>
```

### Frontend Repository:
```
REACT_APP_API_URL=http://<BACKEND_IP>:5000/api
FRONTEND_EC2_HOST=<FRONTEND_IP>
EC2_USERNAME=ubuntu
EC2_SSH_KEY=<contents_of_AbhayOrg.pem>
```

### Backend Repository:
```
BACKEND_EC2_HOST=<BACKEND_IP>
EC2_USERNAME=ubuntu
EC2_SSH_KEY=<contents_of_AbhayOrg.pem>
DB_HOST=<RDS_ENDPOINT_WITHOUT_PORT>
DB_NAME=talentforge
DB_USER=admin
DB_PASSWORD=<YOUR_DB_PASSWORD>
JWT_SECRET=<YOUR_JWT_SECRET>
CORS_ORIGIN=http://<FRONTEND_IP>
AWS_S3_BUCKET=talentforge-uploads-bucket
```

### Terraform Repository:
```
TF_STATE_BUCKET=talentforge-terraform-state
DB_PASSWORD=<YOUR_DB_PASSWORD>
JWT_SECRET=<YOUR_JWT_SECRET>
```

---

## 🔄 Future Deployments via CI/CD

Once GitHub secrets are configured:

1. **Code Changes**: Push to main branch
2. **Automatic Build**: GitHub Actions builds Docker image
3. **Automatic Deploy**: SSH into EC2 and updates container
4. **Zero Downtime**: Rolling updates

---

## 🛠️ Troubleshooting

### EC2 Instance Not Starting
```bash
# Check EC2 console for status
aws ec2 describe-instances --filters "Name=tag:Name,Values=talentforge-*" --region us-east-1
```

### User Data Script Failed
```bash
# SSH and check logs
ssh -i AbhayOrg.pem ubuntu@<EC2_IP>
cat /var/log/userdata.log
cat /var/log/cloud-init-output.log
```

### Docker Container Not Running
```bash
# Check container status
docker ps -a

# Check container logs
docker logs talentforge-backend
docker logs talentforge-frontend
```

### Database Connection Issues
```bash
# Test RDS connectivity from Backend EC2
telnet <RDS_ENDPOINT> 3306

# Check security group rules
aws ec2 describe-security-groups --group-ids <RDS_SG_ID> --region us-east-1
```

### S3 Access Issues
```bash
# Check IAM role attached to EC2
aws iam get-instance-profile --instance-profile-name talentforge-instance-profile

# Test S3 access from EC2
aws s3 ls s3://talentforge-uploads-bucket
```

---

## 🧹 Cleanup (Destroy Infrastructure)

To avoid AWS charges:

```bash
cd talentforge-terraform
terraform destroy
```

Type `yes` to confirm deletion of all resources.

**Note**: This will delete:
- All EC2 instances
- RDS database (all data will be lost)
- S3 bucket (if empty)
- VPC and networking

---

## 📊 Cost Estimation

Expected monthly AWS costs (us-east-1):
- **EC2 t2.micro (2x)**: ~$16/month ($8 each)
- **RDS db.t3.micro**: ~$15/month
- **S3 Storage**: ~$0.50/month (for 20GB)
- **Data Transfer**: ~$5/month
- **Total**: ~$36-40/month

---

## ✅ Deployment Complete!

Your TalentForge application is now running on AWS:
- **Frontend**: http://<FRONTEND_IP>:3000
- **Backend API**: http://<BACKEND_IP>:5000
- **Database**: Managed by AWS RDS
- **File Storage**: AWS S3

**Default Login Credentials** (from seed data):
- Username: `admin`
- Password: `Password123`

---

## 🎯 Next Steps

1. Configure a domain name (Route 53)
2. Set up SSL/TLS certificates (ACM + Load Balancer)
3. Enable CloudWatch monitoring
4. Set up automated backups for RDS
5. Implement WAF for security
6. Add CloudFront for CDN
