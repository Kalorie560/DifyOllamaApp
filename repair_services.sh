#\!/bin/bash
set -e

echo "==============================================="
echo "Repairing Dify Ollama Integration Services"
echo "==============================================="

# Get local IP address
export IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Using IP address: $IP_ADDRESS"

# 1. Create a completely new nginx.conf file
echo "Creating new nginx configuration..."
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
        listen [::]:5000 default_server;
        server_name _;

        # Handle preflight OPTIONS requests
        if ($request_method = 'OPTIONS') {
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
            
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization' always;
        }
    }

    server {
        listen 3000 default_server;
        listen [::]:3000 default_server;
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
            
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization' always;
        }
    }
}
NGINX_EOF

# 2. Update docker-compose.yml with correct variables
echo "Updating docker-compose.yml..."
cat > docker-compose.yml << EOF
services:
  api:
    image: langgenius/dify-api:latest
    restart: always
    environment:
      # Deployment config
      - DEPLOY_ENV=production
      # Postgres config
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify
      # Redis config
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=
      - REDIS_USE_SSL=False
      # File storage config, local or s3
      - STORAGE_TYPE=local
      - STORAGE_LOCAL_PATH=/app/api/storage
      - WEB_API_URL=http://$IP_ADDRESS:3000
      # Web config
      - CONSOLE_API_URL=http://api:5001
      - CONSOLE_WEB_URL=http://$IP_ADDRESS:3000
      - SERVICE_API_URL=http://api:5001
      - FILES_URL=http://api:5001
      - CORS_ALLOW_ORIGINS=*
      # Logging config
      - LOGGING_LEVEL=INFO
      - LOGGING_CONF_PATH=/app/api/logging.conf
      # Secret key
      - SECRET_KEY=8dHaUO8ekynMvoZ2G1kD339zWQyXjNUML7IRYyp35dc
      # Vector database provider
      - PGVECTOR_DRIVER=pgvector
      # Celery backend
      - CELERY_BROKER_TYPE=redis
      - CELERY_BROKER_URL=redis://:@redis:6379/0
      - CELERY_BACKEND_URL=redis://:@redis:6379/1
      # File upload
      - UPLOAD_FILE_SIZE_LIMIT=50
      - UPLOAD_FILE_TOTAL_LIMIT=50
      # Important for OpenDAL (fixes storage errors)
      - OPENDAL_SCHEME=local
      - OPENDAL_ROOT=/app/api/storage
    volumes:
      - ./data/dify/storage:/app/api/storage
    depends_on:
      - db
      - redis
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - dify-network

  worker:
    image: langgenius/dify-api:latest
    restart: always
    command: celery -A app.celery worker -l INFO -n worker@%h
    environment:
      # Deployment config
      - DEPLOY_ENV=production
      # Postgres config
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify
      # Redis config
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=
      - REDIS_USE_SSL=False
      # File storage config, local or s3
      - STORAGE_TYPE=local
      - STORAGE_LOCAL_PATH=/app/api/storage
      # Web config
      - CONSOLE_API_URL=http://api:5001
      - CONSOLE_WEB_URL=http://$IP_ADDRESS:3000
      - SERVICE_API_URL=http://api:5001
      - FILES_URL=http://api:5001
      - CORS_ALLOW_ORIGINS=*
      # Vector database provider
      - PGVECTOR_DRIVER=pgvector
      # Celery backend
      - CELERY_BROKER_TYPE=redis
      - CELERY_BROKER_URL=redis://:@redis:6379/0
      - CELERY_BACKEND_URL=redis://:@redis:6379/1
      # Secret key
      - SECRET_KEY=8dHaUO8ekynMvoZ2G1kD339zWQyXjNUML7IRYyp35dc
      # Logging config
      - LOGGING_LEVEL=INFO
      - LOGGING_CONF_PATH=/app/api/logging.conf
      # File upload
      - UPLOAD_FILE_SIZE_LIMIT=50
      - UPLOAD_FILE_TOTAL_LIMIT=50
      # Important for OpenDAL (fixes storage errors)
      - OPENDAL_SCHEME=local
      - OPENDAL_ROOT=/app/api/storage
    volumes:
      - ./data/dify/storage:/app/api/storage
    depends_on:
      - db
      - redis
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - dify-network

  web:
    image: langgenius/dify-web:latest
    restart: always
    environment:
      - API_URL=http://api:5001
      - API_PREFIX=/api
      - CONSOLE_API_URL=http://api:5001
      - PUBLIC_ORIGIN=http://$IP_ADDRESS:3000/
    depends_on:
      - api
    networks:
      - dify-network

  db:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=dify
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - ./data/dify/postgres-data:/var/lib/postgresql/data
    networks:
      - dify-network

  redis:
    image: redis:6-alpine
    restart: always
    volumes:
      - ./data/dify/redis-data:/data
    networks:
      - dify-network
  
  nginx:
    image: nginx:alpine
    ports:
      - "0.0.0.0:5000:5000"
      - "0.0.0.0:3000:3000"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api
      - web
    networks:
      - dify-network

networks:
  dify-network:
    driver: bridge
