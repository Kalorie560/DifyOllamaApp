#\!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$DIR/venv"

# Activate the virtual environment if it exists
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Get local IP address
ip_address=$(hostname -I | awk '{print $1}')

echo "Checking service status..."
echo "-------------------------"

# Check Docker services
echo "Docker containers:"
docker compose ps

echo -e "\nDify Web status:"
if curl -s -o /dev/null -w "%{http_code}" http://$ip_address:3000 2>/dev/null | grep -q "200"; then
    echo "✅ Dify Web is running at http://$ip_address:3000"
else
    echo "❌ Dify Web is not responding"
fi

echo -e "\nDify API status:"
if curl -s -o /dev/null -w "%{http_code}" http://$ip_address:5000/api/v1/health 2>/dev/null | grep -q "200"; then
    echo "✅ Dify API is running at http://$ip_address:5000"
else
    echo "❌ Dify API is not responding at http://$ip_address:5000"
    # Try direct API port
    if curl -s -o /dev/null -w "%{http_code}" http://$ip_address:5001/api/v1/health 2>/dev/null | grep -q "200"; then
        echo "✅ But Dify API is running directly at http://$ip_address:5001"
    fi
fi

echo -e "\nOllama status:"
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "✅ Ollama is running at http://localhost:11434"
    # Check if Ollama is accessible externally
    if curl -s -m 2 "http://$ip_address:11434/api/tags" > /dev/null 2>&1; then
        echo "✅ Ollama is accessible externally at http://$ip_address:11434"
    else
        echo "❌ Ollama is NOT accessible externally at http://$ip_address:11434"
        echo "   You may need to configure Ollama to listen on all interfaces."
        echo "   See instructions in the README or run 'systemctl status ollama' to check."
    fi
    
    # Get and display available models
    echo -e "\nAvailable Ollama models:"
    curl -s "http://localhost:11434/api/tags" | grep -o '"name":"[^"]*' | sed 's/"name":"/- /'
else
    echo "❌ Ollama is not responding"
fi

echo -e "\nListening ports:"
sudo ss -tulnp | grep -E ':(3000|5000|5001|11434)' || echo "No services found on expected ports"

echo -e "\nSystem information:"
echo "Memory usage:"
free -h

echo -e "\nDisk usage:"
df -h | grep -E '(Filesystem|/dev/|Avail)'
