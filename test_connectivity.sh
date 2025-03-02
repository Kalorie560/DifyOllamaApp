#\!/bin/bash

echo "Testing Dify and Ollama Connectivity"
echo "==================================="

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Local IP address: $IP_ADDRESS"

# Test local connectivity first
echo -e "\nTesting local connectivity (from this machine):"
echo -n "Ollama API (11434): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags 2>/dev/null; then
    echo "✅ Accessible locally"
else
    echo "❌ NOT accessible locally - check if Ollama is running"
fi

echo -n "Dify Web UI (3000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null; then
    echo "✅ Accessible locally"
else
    echo "❌ NOT accessible locally - check Docker container"
fi

echo -n "Dify API (5000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 2>/dev/null; then
    echo "✅ Accessible locally"
else
    echo "❌ NOT accessible locally - check Docker container"
fi

# Test LAN connectivity
echo -e "\nTesting LAN connectivity (via IP address):"
echo -n "Ollama API (11434): "
if curl -s -o /dev/null -w "%{http_code}" http://$IP_ADDRESS:11434/api/tags 2>/dev/null; then
    echo "✅ Accessible over LAN"
else
    echo "❌ NOT accessible over LAN - check firewall/binding"
fi

echo -n "Dify Web UI (3000): "
if curl -s -o /dev/null -w "%{http_code}" http://$IP_ADDRESS:3000 2>/dev/null; then
    echo "✅ Accessible over LAN"
else
    echo "❌ NOT accessible over LAN - check firewall/binding"
fi

echo -n "Dify API (5000): "
if curl -s -o /dev/null -w "%{http_code}" http://$IP_ADDRESS:5000 2>/dev/null; then
    echo "✅ Accessible over LAN"
else
    echo "❌ NOT accessible over LAN - check firewall/binding"
fi

# Check ports
echo -e "\nChecking listening ports:"
sudo ss -tulnp | grep -E ':(3000|5000|5001|11434)'

# Check firewall status
echo -e "\nChecking firewall status:"
if command -v ufw &>/dev/null; then
    sudo ufw status
elif command -v iptables &>/dev/null; then
    sudo iptables -L | grep -E '(3000|5000|11434|DROP)'
else
    echo "No firewall detected"
fi

echo -e "\nAccess URLs to try from other devices:"
echo "- Web UI: http://$IP_ADDRESS:3000"
echo "- API: http://$IP_ADDRESS:5000"
echo "- Ollama: http://$IP_ADDRESS:11434"

echo -e "\nIf you're still having issues, try the 'repair_services.sh' script."
