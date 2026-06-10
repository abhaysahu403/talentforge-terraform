# Fix Frontend API Communication Issue

## Problem
The React frontend has `http://localhost:5000/api` hardcoded in the compiled JavaScript bundle, causing CORS errors when trying to communicate with the backend API.

## Solution
Deploy the updated nginx configuration that uses `sub_filter` directive to rewrite the localhost URLs on-the-fly.

---

## Step-by-Step Fix

### Step 1: Connect to Frontend EC2
```bash
ssh -i AbhayOrg.pem ubuntu@100.55.88.10
```

### Step 2: Create the Updated Nginx Config
Copy and paste this entire block into your SSH session:

```bash
cat > /tmp/default.conf << 'EOF'
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
    
    # Override localhost:5000 with backend proxy - THIS IS THE KEY FIX
    sub_filter 'http://localhost:5000/api' '/api';
    sub_filter_once off;
    sub_filter_types application/javascript;

    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://3.230.115.251:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' 'http://100.55.88.10' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Cache static assets aggressively
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
EOF
```

### Step 3: Verify the Config File Was Created
```bash
cat /tmp/default.conf
```

You should see the nginx configuration with the `sub_filter` directives.

### Step 4: Copy Config to Docker Container
```bash
sudo docker cp /tmp/default.conf talentforge-frontend:/etc/nginx/conf.d/default.conf
```

### Step 5: Test Nginx Configuration
```bash
sudo docker exec talentforge-frontend nginx -t
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 6: Reload Nginx
```bash
sudo docker exec talentforge-frontend nginx -s reload
```

### Step 7: Verify Container is Running
```bash
sudo docker ps | grep talentforge-frontend
sudo docker logs talentforge-frontend --tail 20
```

### Step 8: Test the Application
Open your browser and navigate to:
```
http://100.55.88.10
```

---

## Testing Login

1. **Open**: http://100.55.88.10
2. **Email**: `admin@talentforge.com` (⚠️ Use EMAIL, not username)
3. **Password**: `Password123`

### Other Test Users
- hr@talentforge.com / Password123
- manager@talentforge.com / Password123
- alice@talentforge.com / Password123

---

## Verification Tests

### 1. Test Frontend Health
```bash
curl http://100.55.88.10/healthz
```
Expected: `OK`

### 2. Test Backend API through Proxy
```bash
curl http://100.55.88.10/api/health
```
Expected: `{"status":"ok","service":"TalentForge API","version":"1.0.0"}`

### 3. Check Browser Console
Open http://100.55.88.10 in your browser, open DevTools (F12), and check:
- Network tab: API calls should go to `/api/*` (not `localhost:5000`)
- Console tab: No CORS errors

---

## What This Fix Does

1. **sub_filter Directive**: Rewrites `http://localhost:5000/api` to `/api` in JavaScript files served to the browser
2. **API Proxy**: Routes all `/api/*` requests from the frontend to the backend at `http://3.230.115.251:5000/api/*`
3. **CORS Headers**: Allows frontend at `http://100.55.88.10` to make requests to the backend

---

## Troubleshooting

### If Login Still Fails

1. **Check Browser Console** (F12):
   - Look for any error messages
   - Check Network tab for failed requests

2. **Check Backend Logs**:
   ```bash
   # On Backend EC2 (3.230.115.251)
   ssh -i AbhayOrg.pem ubuntu@3.230.115.251
   sudo docker logs talentforge-backend --tail 50
   ```

3. **Test Backend Directly**:
   ```bash
   curl -X POST http://3.230.115.251:5000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@talentforge.com","password":"Password123"}'
   ```

4. **Verify sub_filter is Working**:
   ```bash
   curl http://100.55.88.10/static/js/main.*.js | grep -o "localhost:5000\|/api"
   ```
   - Should show `/api` (good)
   - Should NOT show `localhost:5000` (bad)

### If Nothing Works

**Alternative Solution**: Rebuild frontend with correct API URL

1. Update `.env` file in frontend repo:
   ```
   REACT_APP_API_URL=http://100.55.88.10/api
   ```

2. Rebuild Docker image with correct API URL
3. Push to Docker Hub
4. Pull and restart container on Frontend EC2

---

## Quick Reference

### Frontend EC2
- IP: 100.55.88.10
- SSH: `ssh -i AbhayOrg.pem ubuntu@100.55.88.10`
- Container: talentforge-frontend

### Backend EC2
- IP: 3.230.115.251
- SSH: `ssh -i AbhayOrg.pem ubuntu@3.230.115.251`
- Container: talentforge-backend

### Database
- Endpoint: talentforge-mysql.c4v4iiimki7h.us-east-1.rds.amazonaws.com
- User: admin
- Password: TalentForge123!

---

## Success Criteria

✅ Frontend loads at http://100.55.88.10  
✅ Login page appears  
✅ No CORS errors in browser console  
✅ API calls go to `/api/*` (not `localhost:5000`)  
✅ Can login with admin@talentforge.com / Password123  
✅ Dashboard loads after login  

---

**After completing these steps, your frontend should be able to communicate with the backend successfully!**
