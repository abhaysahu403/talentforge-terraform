# Complete Automation Plan

## Current Manual Steps That Need Automation

### What We Did Manually:
1. ✅ Pull Docker images from Docker Hub (instead of building locally)
2. ✅ Start Frontend container with proper nginx config (port 80 + 3000)
3. ✅ Start Backend container with all environment variables (DB credentials, JWT, AWS, etc.)
4. ✅ Initialize RDS database (schema.sql + seed.sql)
5. ✅ Deploy updated nginx config with sub_filter for localhost fix

### What Needs to Be Automated:

#### 1. Frontend EC2 User Data
- Install Docker
- Pull pre-built image from Docker Hub: `abhaysahu403/talentforge-frontend:latest`
- Create nginx config file with sub_filter directive
- Run container with nginx config mounted
- Expose ports 80 and 3000

#### 2. Backend EC2 User Data
- Install Docker and MySQL client
- Pull pre-built image from Docker Hub: `abhaysahu403/talentforge-backend:latest`
- Clone database repository
- Wait for RDS to be ready
- Initialize database (schema.sql + seed.sql)
- Run backend container with all environment variables:
  - DB_HOST (from RDS endpoint)
  - DB credentials
  - JWT_SECRET
  - AWS credentials
  - S3 bucket name
  - CORS_ORIGIN

#### 3. Terraform Improvements
- Use `templatefile()` to inject RDS endpoint into user data scripts
- Pass all necessary variables to EC2 modules
- Add null_resource with provisioners for database initialization
- Add depends_on to ensure proper resource creation order

#### 4. GitHub Actions (Optional)
- Automate terraform apply on push
- Store AWS credentials as secrets
- Auto-deploy on merge to main branch

---

## Implementation Steps

### Step 1: Update Frontend User Data Script
Create new `userdata-frontend.tpl` template with:
- Docker Hub image pull
- Nginx config with sub_filter
- Container startup on port 80

### Step 2: Update Backend User Data Script
Create new `userdata-backend.tpl` template with:
- Docker Hub image pull
- Database initialization logic
- Container startup with environment variables

### Step 3: Update Terraform Modules
- Add RDS endpoint as variable to backend EC2
- Use templatefile() for dynamic user data
- Add null_resource for database initialization

### Step 4: Create GitHub Actions Workflow
- Terraform plan on PR
- Terraform apply on merge to main
- Store tfstate in S3 backend (optional)

---

## Files to Create/Modify:

### New Files:
1. `modules/frontend-ec2/userdata-frontend.tpl` - Automated frontend setup
2. `modules/backend-ec2/userdata-backend.tpl` - Automated backend setup
3. `.github/workflows/terraform-deploy.yml` - GitHub Actions workflow

### Modified Files:
1. `modules/frontend-ec2/main.tf` - Use templatefile()
2. `modules/backend-ec2/main.tf` - Use templatefile() with RDS endpoint
3. `main.tf` - Pass RDS endpoint to backend module
4. `variables.tf` - Add new variables (JWT secret, etc.)
5. `terraform.tfvars` - Set variable values

---

## Testing Plan

### Test 1: Fresh Deployment
```bash
terraform destroy -auto-approve
terraform apply -auto-approve
# Wait 10 minutes
# Test: http://<frontend-ip>
# Login: admin@talentforge.com / Password123
```

### Test 2: GitHub Actions
```bash
git add .
git commit -m "Automated deployment"
git push origin main
# Check GitHub Actions tab
# Verify deployment succeeds
```

---

## Rollback Plan

If automation fails:
1. Keep current tfstate as backup
2. Manual intervention documented in FIX_FRONTEND_MANUAL.md
3. Git revert to previous working state

---

## Next Actions

1. Create automated user data scripts
2. Update Terraform modules
3. Test fresh deployment
4. Create GitHub Actions workflow
5. Document final solution
6. Commit and push to Git

