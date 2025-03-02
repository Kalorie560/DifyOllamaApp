#\!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get local IP address for display purposes
export IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "Using IP address: $IP_ADDRESS for network configurations"

echo "Starting Dify with Ollama integration..."
echo "----------------------------------------"

# Check if Ollama is already running locally
if curl -s -m 2 "http://localhost:11434/api/tags" > /dev/null; then
    echo "✅ Ollama is already running locally"
    
    # List available models
    echo -e "\nAvailable Ollama models:"
    curl -s "http://localhost:11434/api/tags" | grep -o '"name":"[^"]*' | sed 's/"name":"/- /'
else
    echo "❌ Ollama is not running locally\!"
    echo "   Please ensure Ollama is configured to listen on all interfaces."
    echo "   Checking Ollama service status..."
    systemctl status ollama
    echo ""
    echo "   If Ollama is not running, start it with: sudo systemctl start ollama"
    exit 1
fi

# Start Docker Compose services
echo -e "\nStarting Dify services..."
docker compose down
docker compose up -d

# Display information
echo -e "\n----------------------------------------"
echo "Dify is starting up\!"
echo "Initial startup may take several minutes (up to 5 minutes on first run)."
echo ""
echo "Access Dify via your web browser at:"
echo "- http://$IP_ADDRESS:3000 (Web UI)"
echo "- http://$IP_ADDRESS:5000 (API)"
echo ""
echo "LAN Access: Other devices on your network can access Dify at:"
echo "- http://$IP_ADDRESS:3000 (Web UI from any device on your network)"
echo "- http://$IP_ADDRESS:5000 (API from any device on your network)"
echo ""
echo "To configure Ollama in Dify:"
echo "1. Go to http://$IP_ADDRESS:3000 and register an account"
echo "2. In Dify, go to Settings > Model Providers > Add Provider > Custom"
echo "3. Set Provider Name to: Ollama-ModelName (e.g., Ollama-Qwen)"
echo "4. Set Base URL to: http://$IP_ADDRESS:11434"
echo "5. Set Chat Endpoint to: /api/chat"
echo "6. Set Completion Endpoint to: /api/generate"
echo "7. Set Model Name to match your Ollama model (e.g., qwen:0.5b)"
echo "8. Click Test and Save"
echo ""
echo "To check status: ./check_status.sh"
echo "To view logs: docker compose logs -f"
echo "To stop services: ./stop_app.sh"
echo "----------------------------------------"
