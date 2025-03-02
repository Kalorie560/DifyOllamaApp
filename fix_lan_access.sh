#\!/bin/bash
set -e

echo "Fixing LAN access for DifyOllamaApp..."
echo "======================================="

# Step 1: Ensure Ollama is listening on all interfaces
echo "Step 1: Configuring Ollama to listen on all interfaces..."
if \! grep -q "OLLAMA_HOST=0.0.0.0:11434" /etc/systemd/system/ollama.service.d/override.conf 2>/dev/null; then
    echo "Configuring Ollama to listen on all network interfaces..."
    echo '[Service]' > /tmp/ollama-override.conf
    echo 'Environment="OLLAMA_HOST=0.0.0.0:11434"' >> /tmp/ollama-override.conf
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo cp /tmp/ollama-override.conf /etc/systemd/system/ollama.service.d/override.conf
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    echo "✅ Ollama configured for LAN access"
else
    echo "✅ Ollama is already configured for LAN access"
fi

# Step 2: Fix docker-compose.yml with IP address
echo "Step 2: Configuring Docker Compose with correct IP address..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Using IP address: $IP_ADDRESS"

# Update docker-compose.yml with actual IP address
sed -i "s/\${IP_ADDRESS}/$IP_ADDRESS/g" docker-compose.yml
sed -i "s/http:\/\/192.168.1.16/http:\/\/$IP_ADDRESS/g" docker-compose.yml

# Create .env file for Docker Compose
echo "IP_ADDRESS=$IP_ADDRESS" > .env

# Restart the Docker containers
echo "Step 3: Restarting Docker containers with new settings..."
docker compose down -v
docker compose up -d

# Wait for services to start
echo "Waiting for services to start up (30 seconds)..."
sleep 30

# Update the Nginx configuration to properly handle API routes
echo "Step 4: Updating Nginx configuration for proper API routing..."
cat > nginx.conf << 'NGINX_EOF'
worker_processes auto;
pid /tmp/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /dev/stdout;
    sendfile on;
    keepalive_timeout 65;
    proxy_read_timeout 300s;
    proxy_connect_timeout 300s;

    upstream api {
        server api:5001;
    }

    upstream web {
        server web:3000;
    }

    server {
        listen 5000 default_server;
        server_name _;

        # CORS headers for all responses
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization' always;

        # Pre-flight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            add_header 'Content-Type' 'text/plain charset=UTF-8' always;
            add_header 'Content-Length' 0 always;
            return 204;
        }

        location / {
            proxy_pass http://api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_http_version 1.1;
            client_max_body_size 100M;
        }
    }

    server {
        listen 3000 default_server;
        server_name _;

        location / {
            proxy_pass http://web;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_http_version 1.1;
            client_max_body_size 100M;
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS, PUT, DELETE';
            add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';
            proxy_buffering off;
        }
    }
}
NGINX_EOF

# Restart nginx container to apply configuration
docker compose restart nginx
sleep 5

# Final check
echo "Step 5: Final verification..."
echo "Verifying Ollama access..."
if curl -s -m 2 "http://$IP_ADDRESS:11434/api/tags" > /dev/null; then
    echo "✅ Ollama is accessible from LAN at http://$IP_ADDRESS:11434"
else
    echo "❌ Ollama is NOT accessible from LAN. Please check firewall settings."
fi

echo "Verifying Docker containers..."
docker compose ps

echo ""
echo "✅ Setup complete. Your Dify application should now be accessible from LAN."
echo ""
echo "Access URLs:"
echo "- Dify Web UI: http://$IP_ADDRESS:3000"
echo "- Dify API: http://$IP_ADDRESS:5000"
echo "- Ollama API: http://$IP_ADDRESS:11434"
echo ""
echo "Important: When configuring Ollama in Dify, use http://$IP_ADDRESS:11434 as the Base URL"
echo ""
echo "If you still have issues, try the following:"
echo "1. Verify no firewall is blocking ports 3000, 5000, and 11434"
echo "2. Ensure other machines on the LAN can ping this machine at $IP_ADDRESS"
echo "3. Run ./check_status.sh for detailed status information"
echo "4. Check Docker logs with: docker compose logs"
