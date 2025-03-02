#\!/bin/bash

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Update docker-compose.yml with actual IP address
sed -i "s/\${IP_ADDRESS}/$IP_ADDRESS/g" docker-compose.yml

echo "Updated docker-compose.yml with IP address $IP_ADDRESS"

# Also create a .env file for docker-compose
echo "IP_ADDRESS=$IP_ADDRESS" > .env

# Restart the services
docker compose down
docker compose up -d

echo "Services restarted with correct IP: $IP_ADDRESS"
