#!/bin/bash
set -e

# Logging
exec > >(tee /var/log/userdata.log) 2>&1
echo "=== Backend Setup Started at $(date) ==="

# Update system
echo "Updating system packages..."
apt-get update -y

# Install Docker, Git, and MySQL client
echo "Installing Docker, Git, and MySQL client..."
apt-get install -y docker.io git mysql-client

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Wait for Docker to be ready
sleep 5

# Pull pre-built backend image from Docker Hub
echo "Pulling backend Docker image from Docker Hub..."
docker pull abhaysahu403/talentforge-backend:latest

# Clone database repository for schema and seed data
echo "Cloning database repository..."
cd /home/ubuntu
git clone https://github.com/abhaysahu403/talentforge-database.git

# Wait for RDS to be ready
echo "Waiting for RDS database to be ready..."
DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_NAME="${db_name}"

# Wait up to 10 minutes for RDS to be available
for i in {1..60}; do
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" &> /dev/null; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database to be ready... ($i/60)"
    sleep 10
done

# Initialize database with schema
echo "Creating database schema..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /home/ubuntu/talentforge-database/schema.sql

# Seed database with initial data
echo "Seeding database with initial data..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /home/ubuntu/talentforge-database/seed.sql

# Verify tables were created
echo "Verifying database tables..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;"

# Start backend container with all environment variables
echo "Starting backend container..."
docker run -d \
  --name talentforge-backend \
  -p 5000:5000 \
  --restart always \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT=3306 \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME="$DB_NAME" \
  -e JWT_SECRET="${jwt_secret}" \
  -e CORS_ORIGIN="${cors_origin}" \
  -e AWS_REGION="${aws_region}" \
  -e S3_BUCKET="${s3_bucket}" \
  -e PORT=5000 \
  -e NODE_ENV=production \
  abhaysahu403/talentforge-backend:latest

# Wait for container to start
sleep 10

# Verify container is running
echo "Verifying container status..."
docker ps | grep talentforge-backend

# Check container logs
echo "Container logs:"
docker logs talentforge-backend --tail 20

# Test health endpoint
echo "Testing health endpoint..."
sleep 5
curl -f http://localhost:5000/health || echo "Health check pending..."

echo "=== Backend Setup Complete at $(date) ==="
echo "Backend API is running on port 5000"
echo "Database initialized with schema and seed data"
echo "Health check: curl http://localhost:5000/health"
