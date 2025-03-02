#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$DIR/venv"

# Activate the virtual environment if it exists
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

echo "Checking service status..."
echo "-------------------------"

# Check Docker services
echo "Docker containers:"
docker compose ps

echo -e "\nDify Web status:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200"; then
    echo "✅ Dify Web is running at http://localhost:3000"
else
    echo "❌ Dify Web is not responding"
fi

echo -e "\nDify API status:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/api/v1/health 2>/dev/null | grep -q "200"; then
    echo "✅ Dify API is running at http://localhost:5001"
else
    echo "❌ Dify API is not responding"
fi

echo -e "\nNginx Proxy status:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200"; then
    echo "✅ Nginx proxy is running at http://localhost"
else
    echo "❌ Nginx proxy is not responding"
fi

echo -e "\nOllama status:"
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "✅ Ollama is running at http://localhost:11434"
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