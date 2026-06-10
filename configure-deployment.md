# TalentForge Deployment Configuration Steps

## Current Status: ✅ Infrastructure Created

All AWS resources have been successfully deployed!

---

## Step 1: Wait for User Data Scripts (REQUIRED)

The EC2 instances are currently installing Docker, cloning repos, and building images.

**Check Frontend Progress:**
```bash
ssh -i AbhayOrg.pem ubuntu@100.55.88.10 "tail -20 /var/log/userdata.log"
```

**Check Backend Progress:**
```bash
ssh -i AbhayOrg.pem ubuntu@3.230.115.251 "tail -20 /var/log/userdata.log"
```

Look for "Setup Complete" messages. This takes 5-10 minutes.

---

## Step 2: Initialize Database

Once backend EC2 is ready, initialize the RDS database:

```bash
# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@3.230.115.251

# Install MySQL client
sudo apt update && sudo apt install mysql-client git -y

# Clone database repository
git clone https://github.com/abhaysahu403/talentforge-database.git
cd talentforge-database

# Initialize database (password: TalentForge123!)
mysql -h talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com -u admin -p talentforge < schema.sql

mysql -h talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com -u admin -p talentforge < seed.sql

# Verify
mysql -h talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com -u admin -p talentforge -e "SHOW TABLES;"

# Exit SSH
exit
```

---

## Step 3: Update Backend Environment

Configure backend to connect to RDS and S3:

```bash
# SSH into Backend EC2
ssh -i AbhayOrg.pem ubuntu@3.230.115.251

# Stop existing container
docker stop talentforge-backend
docker rm talentforge-backend

# Run with correct environment variables
docker run -d \
  --name talentforge-backend \
  -p 5000:5000 \
  -e DB_HOST=talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com \
  -e DB_PORT=3306 \
  -e DB_USER=admin \
  -e DB_PASSWORD=TalentForge123! \
  -e DB_NAME=talentforge \
  -e JWT_SECRET=your-secret-key-here-change-this \
  -e CORS_ORIGIN=http://100.55.88.10:3000 \
  -e AWS_REGION=us-east-1 \
  -e S3_BUCKET=talentforge-uploads-bucket \
  --restart always \
  abhaysahu403/talentforge-backend:latest

# Verify container is running
docker ps

# Check logs
docker logs talentforge-backend

# Exit SSH
exit
```

---

## Step 4: Update Frontend Environment

Configure frontend to connect to backend:

```bash
# SSH into Frontend EC2
ssh -i AbhayOrg.pem ubuntu@100.55.88.10

# Stop existing container
docker stop talentforge-frontend
docker rm talentforge-frontend

# Update environment file
cd talentforge-frontend
echo "REACT_APP_API_URL=http://3.230.115.251:5000/api" > .env

# Rebuild with new environment
docker build -t talentforge-frontend .

# Run updated container
docker run -d \
  --name talentforge-frontend \
  -p 3000:3000 \
  --restart always \
  talentforge-frontend

# Verify
docker ps
docker logs talentforge-frontend

# Exit SSH
exit
```

---

## Step 5: Test Deployment

### Test Backend API

```bash
# Health check
curl http://3.230.115.251:5000/health

# Login test
curl -X POST http://3.230.115.251:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Password123"}'
```

### Test Frontend

Open in browser:
```
http://100.55.88.10:3000
```

Login with:
- Username: `admin`
- Password: `Password123`

---

## Troubleshooting

### User Data Still Running?
```bash
# Check cloud-init status
ssh -i AbhayOrg.pem ubuntu@<EC2_IP> "tail -f /var/log/cloud-init-output.log"
```

### Container Not Running?
```bash
# Check Docker status
ssh -i AbhayOrg.pem ubuntu@<EC2_IP> "docker ps -a"

# Check logs
ssh -i AbhayOrg.pem ubuntu@<EC2_IP> "docker logs <container_name>"
```

### Can't Connect to RDS?
```bash
# Test connectivity
ssh -i AbhayOrg.pem ubuntu@3.230.115.251 "telnet talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com 3306"
```

### Backend API Not Responding?
```bash
# Check backend logs
ssh -i AbhayOrg.pem ubuntu@3.230.115.251 "docker logs talentforge-backend"
```

---

## Quick Commands Summary

```bash
# Check Frontend
ssh -i AbhayOrg.pem ubuntu@100.55.88.10 "docker ps && docker logs talentforge-frontend --tail 50"

# Check Backend
ssh -i AbhayOrg.pem ubuntu@3.230.115.251 "docker ps && docker logs talentforge-backend --tail 50"

# Test API
curl http://3.230.115.251:5000/health

# Open Frontend
start http://100.55.88.10:3000
```

---

## Important Notes

1. **Wait for user data scripts** before proceeding to database initialization
2. **Database password**: TalentForge123!
3. **Application password**: Password123
4. **Save your SSH key** (AbhayOrg.pem) - you need it for all SSH commands
5. **Costs**: ~$40/month - remember to destroy when done learning

---

## Cleanup (When Done)

To destroy all AWS resources and stop charges:

```bash
cd C:\Projects\Telentforge-software\Talentforge\talentforge-terraform
terraform destroy
```

Type `yes` to confirm.

---

## Success Checklist

- [ ] User data scripts completed on both EC2s
- [ ] Database initialized with schema and seed data
- [ ] Backend container running with correct environment
- [ ] Frontend container running with backend API URL
- [ ] Backend health check returns 200 OK
- [ ] Frontend loads in browser
- [ ] Login works with admin/Password123
- [ ] Can navigate through the application

---

🎉 **Your TalentForge application is now deployed on AWS!**
