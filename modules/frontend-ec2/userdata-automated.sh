#!/bin/bash
set -e

# Logging
exec > >(tee /var/log/userdata.log) 2>&1
echo "=== Frontend Setup Started at $(date) ==="

# Update system
echo "Updating system packages..."
apt-get update -y

# Install Docker
echo "Installing Docker..."
apt-get install -y docker.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Wait for Docker to be ready
sleep 5

# Pull pre-built frontend image from Docker Hub
echo "Pulling frontend Docker image from Docker Hub..."
docker pull abhaysahu403/talentforge-frontend:latest

# Create nginx configuration with sub_filter fix
echo "Creating nginx configuration..."
cat > /tmp/default.conf << 'NGINX_CONFIG'
server {
    listen       80;
    server_name  _;

    root   /usr/share/nginx/html;
    index  index.html;

    # Enable gzip compression
    gzip            on;
    gzip_vary       on;
    gzip_proxied    any;
    gzip_comp_level 6;
    gzip_types      text/plain text/css text/xml application/json
                    application/javascript application/rss+xml
                    application/atom+xml image/svg+xml;

    # Security headers
    add_header X-Frame-Options          "SAMEORIGIN"  always;
    add_header X-XSS-Protection         "1; mode=block" always;
    add_header X-Content-Type-Options   "nosniff"     always;
    add_header Referrer-Policy          "strict-origin-when-cross-origin" always;
    
    # FIX: Rewrite localhost:5000 to /api in JavaScript files
    sub_filter 'http://localhost:5000/api' '/api';
    sub_filter_once off;
    sub_filter_types application/javascript;

    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://${backend_ip}:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Cache static assets
    location /static/ {
        expires     1y;
        add_header  Cache-Control "public, immutable";
        access_log  off;
    }

    # Never cache index.html
    location = /index.html {
        add_header  Cache-Control "no-cache, no-store, must-revalidate";
        add_header  Pragma "no-cache";
        add_header  Expires "0";
    }

    # React Router fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check
    location = /healthz {
        return 200 "OK\n";
        add_header Content-Type text/plain;
        access_log off;
    }
}
NGINX_CONFIG

# Start frontend container with custom nginx config
echo "Starting frontend container..."
docker run -d \
  --name talentforge-frontend \
  -p 80:80 \
  -p 3000:3000 \
  --restart always \
  abhaysahu403/talentforge-frontend:latest

# Wait for container to be running
sleep 5

# Copy nginx config into container
echo "Deploying nginx configuration..."
docker cp /tmp/default.conf talentforge-frontend:/etc/nginx/conf.d/default.conf

# Test and reload nginx
echo "Reloading nginx..."
docker exec talentforge-frontend nginx -t
docker exec talentforge-frontend nginx -s reload

# Verify container is running
echo "Verifying container status..."
docker ps | grep talentforge-frontend

echo "=== Frontend Setup Complete at $(date) ==="
echo "Frontend is accessible on port 80 and 3000"
echo "Health check: curl http://localhost/healthz"
