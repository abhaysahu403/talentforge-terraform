# TalentForge - Quick Start Deployment

## 🎯 Fast Track Deployment (15 minutes)

### Prerequisites
- AWS CLI configured (`aws configure`)
- EC2 Key Pair "AbhayOrg" exists in us-east-1
- Terraform installed

---

## Step 1: Deploy Infrastructure (5 min)

```bash
cd talentforge-terraform
terraform apply
# Type: yes
```

**Wait for completion.** Save the outputs:
```bash
terraform output > outputs.txt
cat outputs.txt
```

---

## Step 2: Get EC2 IPs

```bash
# Frontend IP
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
echo "Frontend: $FRONTEND_IP"

# Backend IP  
BACKEND_IP=$(terraform output -raw backend_public_ip)
echo "Backend: $BACKEND_IP"

# RDS Endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint | cut -d: -f1)
echo "RDS: $RDS_ENDPOINT"
```

---

## Step 3: Wait for User Data Scripts (5 min)

Check if EC2 setup is complete:

```bash
# Frontend
ssh -i AbhayOrg.pem ubuntu@$FRONTEND_IP "tail /var/log/userdata.log"

# Backend
ssh -i AbhayOrg.pem ubuntu@$BACKEND_IP "tail /var/log/userdata.log"
```

Look for "Setup Complete" message.

---

## Step 4: Initialize Database (2 min)

```bash
# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@$BACKEND_IP

# Install MySQL client
sudo apt update && sudo apt install mysql-client git -y

# Clone database repo
git clone https://github.com/abhaysahu403/talentforge-database.git
cd talentforge-database

# Initialize database (password: TalentForge123!)
mysql -h <RDS_ENDPOINT> -u admin -p talentforge < schema.sql
mysql -h <RDS_ENDPOINT> -u admin -p talentforge < seed.sql

# Exit SSH
exit
```

---

## Step 5: Update Backend Environment (3 min)

```bash
# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@$BACKEND_IP

# Stop existing container
docker stop talentforge-backend
docker rm talentforge-backend

# Run with correct environment
docker run -d \
  --name talentforge-backend \
  -p 5000:5000 \
  -e DB_HOST=<RDS_ENDPOINT> \
  -e DB_PORT=3306 \
  -e DB_USER=admin \
  -e DB_PASSWORD=TalentForge123! \
  -e DB_NAME=talentforge \
  -e JWT_SECRET=$(openssl rand -base64 32) \
  -e CORS_ORIGIN=http://<FRONTEND_IP> \
  -e AWS_REGION=us-east-1 \
  -e S3_BUCKET=talentforge-uploads-bucket \
  --restart always \
  abhaysahu403/talentforge-backend:latest

# Exit SSH
exit
```

---

## Step 6: Update Frontend Environment (3 min)

```bash
# SSH into Frontend EC2
ssh -i AbhayOrg.pem ubuntu@$FRONTEND_IP

# Stop existing container
docker stop talentforge-frontend
docker rm talentforge-frontend

# Update and rebuild
cd talentforge-frontend
echo "REACT_APP_API_URL=http://<BACKEND_IP>:5000/api" > .env
docker build -t talentforge-frontend .

# Run updated container
docker run -d \
  --name talentforge-frontend \
  -p 3000:3000 \
  --restart always \
  talentforge-frontend

# Exit SSH
exit
```

---

## ✅ Test Deployment

### Browser Test
```
http://<FRONTEND_IP>:3000
```

### API Test
```bash
curl http://<BACKEND_IP>:5000/health

curl -X POST http://<BACKEND_IP>:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Password123"}'
```

---

## 🔑 Default Credentials

**Application Login:**
- Username: `admin`
- Password: `Password123`

**Database:**
- Host: `<RDS_ENDPOINT>`
- User: `admin`
- Password: `TalentForge123!`
- Database: `talentforge`

---

## 🛑 Destroy Everything

```bash
cd talentforge-terraform
terraform destroy
# Type: yes
```

---

## 📝 Important URLs

- **GitHub Repos**:
  - Frontend: https://github.com/abhaysahu403/talentforge-frontend.git
  - Backend: https://github.com/abhaysahu403/talentforge-backend.git
  - Database: https://github.com/abhaysahu403/talentforge-database.git
  - Terraform: https://github.com/abhaysahu403/talentforge-terraform.git

- **Docker Hub**:
  - Frontend: abhaysahu403/talentforge-frontend:latest
  - Backend: abhaysahu403/talentforge-backend:latest

---

## 🚨 Troubleshooting

**Container not running?**
```bash
docker ps -a
docker logs talentforge-backend
docker logs talentforge-frontend
```

**Can't connect to RDS?**
```bash
telnet <RDS_ENDPOINT> 3306
```

**User data not complete?**
```bash
tail -f /var/log/userdata.log
tail -f /var/log/cloud-init-output.log
```

---

## 💰 Estimated Cost

~$40/month for:
- 2x EC2 t2.micro instances
- 1x RDS db.t3.micro
- S3 storage
- Data transfer

---

## 📚 Full Documentation

See `DEPLOYMENT_GUIDE.md` for detailed instructions.
