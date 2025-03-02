#!/bin/bash

# Setup script for Dify with Ollama integration
set -e

# Directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$DIR/config.yaml"
COMPOSE_FILE="$DIR/docker-compose.yml"
VENV_DIR="$DIR/venv"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed."
        return 1
    else
        print_status "$1 is installed: $(command -v $1)"
        return 0
    fi
}

# Check system requirements
print_status "Checking system requirements..."

# Check Docker
if ! check_command docker; then
    print_error "Docker is required. Please install Docker first."
    print_status "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if ! check_command docker-compose; then
    print_warning "Docker Compose is not installed directly but might be included in Docker."
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is required. Please install Docker Compose."
        print_status "Visit: https://docs.docker.com/compose/install/"
        exit 1
    else
        print_status "Docker Compose is available through Docker CLI."
    fi
fi

# Check Python
if ! check_command python3; then
    print_error "Python 3 is required for utility scripts."
    exit 1
fi

# Check Ollama
if ! check_command ollama; then
    print_warning "Ollama is not installed. We'll set up the Docker version instead."
    USE_DOCKER_OLLAMA=true
else
    print_status "Ollama is installed: $(command -v ollama)"
    # Check if Ollama is running
    if ! curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null; then
        print_warning "Ollama is not running. Please start it with 'ollama serve'."
    else
        print_status "Ollama is running."
    fi
    USE_DOCKER_OLLAMA=false
fi

# Create data directories
print_status "Creating data directories..."
mkdir -p "$DIR/data/dify"
mkdir -p "$DIR/data/ollama"

# Setup Python virtual environment
print_status "Setting up Python virtual environment..."
if ! check_command python3-venv; then
    print_warning "python3-venv is not installed. Trying to install it..."
    if [ -f /etc/debian_version ]; then
        print_status "Detected Debian/Ubuntu. Installing python3-venv..."
        sudo apt-get update && sudo apt-get install -y python3-venv
    else
        print_error "Could not automatically install python3-venv. Please install it manually."
        exit 1
    fi
fi

# Create virtual environment
python3 -m venv "$VENV_DIR"
print_status "Virtual environment created at $VENV_DIR"

# Activate virtual environment and install dependencies
print_status "Installing Python dependencies in virtual environment..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install pyyaml requests python-dotenv

# Create .env file
print_status "Creating environment configuration..."
cat > "$DIR/.env" << EOF
# Dify Environment Variables
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_DB=dify
PG_DATA=/var/lib/postgresql/data/pgdata

UPLOAD_FILE_SIZE_LIMIT=50
UPLOAD_FILE_TOTAL_LIMIT=1000

# Worker Environment Variables
CELERY_BROKER_TYPE=redis
CELERY_BROKER_URL=redis://:@dify-redis:6379/0
CELERY_RESULT_BACKEND=redis://:@dify-redis:6379/1
CELERY_TASK_TRACK_STARTED=True
CELERY_TASK_TIME_LIMIT=3600
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP=True

CORS_ALLOW_ORIGINS=*

# Redis environment
REDIS_HOST=dify-redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=

# Database environment
DB_TYPE=postgresql
DB_HOST=dify-postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=dify

CONSOLE_DEMO_MODE=false
CONSOLE_API_PREFIX=/console/api
CONSOLE_WEB_URL=http://localhost:3000

# Storage environment
STORAGE_TYPE=local
STORAGE_LOCAL_PATH=/app/storage
EOF

# Create docker-compose file
print_status "Creating Docker Compose configuration..."

cat > "$COMPOSE_FILE" << 'EOF'
version: '3.1'

services:
  dify-api:
    image: langgenius/dify-api:latest
    restart: unless-stopped
    environment:
      - MODE=api
      - DEBUG=false
      - CONSOLE_URL=http://dify-web:3000
      - FILE_UPLOAD_ENABLED=true
    env_file:
      - .env
    depends_on:
      - dify-postgres
      - dify-redis
    volumes:
      - ./data/dify/storage:/app/storage
    ports:
      - "5000:5000"
    networks:
      - dify-network

  dify-web:
    image: langgenius/dify-web:latest
    restart: unless-stopped
    environment:
      - API_URL=http://dify-api:5000
      - API_PREFIX=/api
      - CONSOLE_API_URL=http://dify-api:5000
    ports:
      - "3000:3000"
    depends_on:
      - dify-api
    networks:
      - dify-network

  dify-worker:
    image: langgenius/dify-api:latest
    restart: unless-stopped
    environment:
      - MODE=worker
      - DEBUG=false
    env_file:
      - .env
    depends_on:
      - dify-postgres
      - dify-redis
    volumes:
      - ./data/dify/storage:/app/storage
    networks:
      - dify-network

  dify-scheduler:
    image: langgenius/dify-api:latest
    restart: unless-stopped
    environment:
      - MODE=scheduler
      - DEBUG=false
    env_file:
      - .env
    depends_on:
      - dify-postgres
      - dify-redis
    volumes:
      - ./data/dify/storage:/app/storage
    networks:
      - dify-network

  dify-postgres:
    image: postgres:14-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - PGDATA=${PG_DATA}
    volumes:
      - ./data/dify/postgres-data:/var/lib/postgresql/data
    networks:
      - dify-network

  dify-redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - ./data/dify/redis-data:/data
    networks:
      - dify-network

  ollama:
    image: ollama/ollama:latest
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./data/ollama:/root/.ollama
    networks:
      - dify-network

networks:
  dify-network:
    driver: bridge
EOF

# Create utility scripts
print_status "Creating utility scripts..."

# Create start_app.sh
cat > "$DIR/start_app.sh" << 'EOF'
#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$DIR/config.yaml"

# Get local IP address for display purposes
ip_address=$(hostname -I | awk '{print $1}')

echo "Starting Dify with Ollama integration..."
echo "----------------------------------------"

# Check if Ollama is already running outside Docker
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null; then
    echo "Ollama is already running locally. You can use it instead of the Docker version."
    echo "To use local Ollama, update the Dify configuration to point to: http://host.docker.internal:11434"
fi

# Start Docker Compose services
docker compose up -d

echo "----------------------------------------"
echo "Services are starting up!"
echo "It may take a few minutes for all services to be fully operational."
echo ""
echo "Access the Dify dashboard at: http://$ip_address:3000"
echo "Access the Dify API at: http://$ip_address:5000"
echo "Access Ollama at: http://$ip_address:11434"
echo ""
echo "To check service status: ./check_status.sh"
echo "To stop services: ./stop_app.sh"
echo "----------------------------------------"
EOF
chmod +x "$DIR/start_app.sh"

# Create stop_app.sh
cat > "$DIR/stop_app.sh" << 'EOF'
#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Stopping Dify with Ollama integration..."
docker compose down

echo "Services stopped successfully."
EOF
chmod +x "$DIR/stop_app.sh"

# Create check_status.sh
cat > "$DIR/check_status.sh" << 'EOF'
#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$DIR/venv"

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

echo "Checking service status..."
echo "-------------------------"

# Check Docker services
echo "Docker containers:"
docker compose ps

echo -e "\nDify API status:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/v1/health 2>/dev/null | grep -q "200"; then
    echo "✅ Dify API is running"
else
    echo "❌ Dify API is not responding"
fi

echo -e "\nDify Web status:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200"; then
    echo "✅ Dify Web is running"
else
    echo "❌ Dify Web is not responding"
fi

echo -e "\nOllama status:"
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "✅ Ollama is running"
    # Get and display available models
    echo -e "\nAvailable Ollama models:"
    curl -s "http://localhost:11434/api/tags" | grep -o '"name":"[^"]*' | sed 's/"name":"/- /'
else
    echo "❌ Ollama is not responding"
fi

echo -e "\nSystem information:"
echo "Memory usage:"
free -h

echo -e "\nDisk usage:"
df -h | grep -E '(Filesystem|/dev/|Avail)'
EOF
chmod +x "$DIR/check_status.sh"

# Create ollama_models.py
cat > "$DIR/ollama_models.py" << 'EOF'
#!/usr/bin/env python3
import argparse
import requests
import sys
import json
import os

OLLAMA_API_HOST = os.environ.get("OLLAMA_API_HOST", "http://localhost:11434")

def check_ollama_running():
    """Check if Ollama service is running."""
    try:
        response = requests.get(f"{OLLAMA_API_HOST}/api/tags", timeout=2)
        return response.status_code == 200
    except requests.exceptions.ConnectionError:
        print("❌ Ollama service is not running")
        print("   To start Ollama, run: ollama serve")
        return False
    except Exception as e:
        print(f"❌ Error checking if Ollama is running: {e}")
        return False

def list_models():
    """List all available models in Ollama."""
    if not check_ollama_running():
        return

    try:
        response = requests.get(f"{OLLAMA_API_HOST}/api/tags")
        if response.status_code == 200:
            data = response.json()
            models = data.get('models', [])
            
            if not models:
                print("No models found in Ollama.")
                print("You can pull models with: ollama pull model_name")
                return
                
            print(f"Found {len(models)} models:")
            for model in models:
                name = model.get('name', 'Unknown')
                size = model.get('size', 0) / (1024 * 1024 * 1024)  # Convert to GB
                modified = model.get('modified', 'Unknown')
                print(f"- {name:20} Size: {size:.2f} GB  Modified: {modified}")
        else:
            print(f"Error: Ollama API returned status code {response.status_code}")
    except Exception as e:
        print(f"Error listing models: {e}")

def pull_model(model_name):
    """Pull a model from Ollama."""
    if not check_ollama_running():
        return

    print(f"Pulling model: {model_name}")
    print("This may take a while depending on the model size...")
    
    try:
        # For simplicity, we'll use os.system instead of streaming the API response
        os.system(f"ollama pull {model_name}")
        print(f"Successfully pulled model: {model_name}")
    except Exception as e:
        print(f"Error pulling model: {e}")

def get_dify_custom_provider_config(model_name):
    """Generate configuration for adding the model as a custom provider in Dify."""
    base_url = OLLAMA_API_HOST.replace("localhost", "host.docker.internal")
    
    config = {
        "provider": "custom",
        "model_name": model_name,
        "chat_endpoint": f"{base_url}/api/chat",
        "completion_endpoint": f"{base_url}/api/generate",
        "parameters": {
            "context_size": 4096,
            "max_tokens": 2048
        }
    }
    
    print("\nTo add this model to Dify as a custom provider, use these settings:")
    print(json.dumps(config, indent=2))
    print("\nIn Dify web interface:")
    print("1. Go to Settings > Model Providers > Add Provider > Custom")
    print("2. Fill in the details above")
    print("3. Test the connection and save")

def main():
    parser = argparse.ArgumentParser(description="Ollama Models Manager")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List available models")
    
    # Pull command
    pull_parser = subparsers.add_parser("pull", help="Pull a model from Ollama")
    pull_parser.add_argument("model_name", help="Name of the model to pull")
    
    # Configure command
    config_parser = subparsers.add_parser("config", help="Get Dify configuration for a model")
    config_parser.add_argument("model_name", help="Name of the model to configure")
    
    args = parser.parse_args()
    
    if args.command == "list":
        list_models()
    elif args.command == "pull":
        pull_model(args.model_name)
    elif args.command == "config":
        get_dify_custom_provider_config(args.model_name)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
chmod +x "$DIR/ollama_models.py"

# Create wrapper script for ollama_models.py
cat > "$DIR/run_ollama_models.sh" << 'EOF'
#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$DIR/venv"

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Run the Python script with arguments
python "$DIR/ollama_models.py" "$@"
EOF
chmod +x "$DIR/run_ollama_models.sh"

# Complete the setup process
print_status "Setup completed successfully!"
print_status "Next steps:"
print_status "1. Start the application: ./start_app.sh"
print_status "2. Access Dify dashboard at: http://$(hostname -I | awk '{print $1}'):3000"
print_status "3. Configure Ollama as a custom provider in Dify (see ./run_ollama_models.sh config command)"
print_status ""
print_status "For more information, check the README.md file."