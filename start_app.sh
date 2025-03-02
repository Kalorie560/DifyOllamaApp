#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get local IP address for display purposes
ip_address=$(hostname -I | awk '{print $1}')

echo "Starting Dify with Ollama integration..."
echo "----------------------------------------"

# Check if Ollama is already running locally
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null; then
    echo "✅ Ollama is already running locally at http://localhost:11434"
    
    # List available models
    echo -e "\nAvailable Ollama models:"
    curl -s "http://localhost:11434/api/tags" | grep -o '"name":"[^"]*' | sed 's/"name":"/- /'
else
    echo "❌ Ollama is not running locally!"
    echo "   Please start Ollama with: ollama serve"
    echo "   Then run this script again."
    exit 1
fi

# Start Docker Compose services
echo -e "\nStarting Dify services..."
docker compose down -v
docker compose up -d

# Display information
echo -e "\n----------------------------------------"
echo "Dify is starting up!"
echo "Initial startup may take several minutes (up to 5 minutes on first run)."
echo ""
echo "Access Dify via your web browser at:"
echo "- http://$ip_address:3000 (Web UI)"
echo "- http://$ip_address:5000 (API)"
echo ""
echo "To configure Ollama in Dify:"
echo "1. Go to http://$ip_address:3000 and register an account"
echo "2. In Dify, go to Settings > Model Providers > Add Provider > Custom"
echo "3. Set Provider Name to: Ollama-ModelName (e.g., Ollama-Qwen)"
echo "4. Set Base URL to: http://host.docker.internal:11434"
echo "5. Set Chat Endpoint to: /api/chat"
echo "6. Set Completion Endpoint to: /api/generate"
echo "7. Set Model Name to match your Ollama model (e.g., qwen:0.5b)"
echo "8. Click Test and Save"
echo ""
echo "To check status: docker compose ps"
echo "To view logs: docker compose logs -f"
echo "To stop services: docker compose down"
echo "----------------------------------------"