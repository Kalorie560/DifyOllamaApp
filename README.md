# Dify with Ollama Integration

This application integrates Dify (an open-source LLM application development platform) with Ollama (a local LLM runner) to create a self-hosted AI application platform that runs completely on your local network.

## Features

- Self-hosted Dify instance running locally
- Integration with Ollama for local LLM support
- Network configuration for access from other devices
- Simple setup and management scripts

## Prerequisites

- Docker and Docker Compose installed
- Ollama installed and running
- At least 4GB RAM (8GB+ recommended)
- 10GB+ disk space

## Quick Start

1. Make sure Ollama is running:
   ```bash
   ollama serve
   ```

2. Start the application:
   ```bash
   ./start_app.sh
   ```

3. Access Dify from your web browser:
   ```
   http://<your-host-ip>:3000
   ```

4. Register an account in Dify and log in

5. Configure Ollama as a custom provider:
   - Go to Settings > Model Providers > Add Provider > Custom
   - Provider Name: "Ollama-ModelName" (e.g., "Ollama-Qwen")
   - Base URL: http://<your-host-ip>:11434  (Use your actual IP address)
   - Chat Endpoint: /api/chat
   - Completion Endpoint: /api/generate
   - Model Name: Use the exact name from Ollama (e.g., qwen:0.5b)
   
   **IMPORTANT**: When configuring from another device on the network, use your host's IP address, 
   not "localhost" or "host.docker.internal". For example: http://192.168.1.16:11434

## Enabling LAN Access

If you're having trouble accessing the services from other devices on your network:

1. Run the LAN access fix script with sudo permissions:
   ```bash
   sudo ./fix_lan_access.sh
   ```

   This script will:
   - Configure Ollama to listen on all network interfaces 
   - Update Docker configurations with proper IP addresses
   - Fix network routing and CORS issues
   - Restart all necessary services

2. Check if the services are running correctly:
   ```bash
   ./check_status.sh
   ```

## Available Models

The application automatically detects Ollama models already installed on your system. Here are some recommended small models that work well on Raspberry Pi:

- qwen:0.5b (0.5 billion parameters)
- phi:1.5b (1.5 billion parameters)
- tinyllama:1.1b (1.1 billion parameters)

Pull a model with:
```bash
ollama pull model_name
```

## Commands

- Start application: `./start_app.sh`
- Stop application: `docker compose down`
- View logs: `docker compose logs -f`
- Check status: `docker compose ps`

## Troubleshooting

If you encounter issues:
- First startup may take several minutes (up to 5 minutes)
- Check logs with `docker compose logs -f api` or `docker compose logs -f web`
- Verify Ollama is running with `curl localhost:11434/api/tags`
- If you see storage errors, make sure OPENDAL_ROOT is properly set

### LAN Access Issues

If you're having trouble accessing Dify from other devices on your network:

1. **Run the test connectivity script first**:
   ```bash
   ./test_connectivity.sh
   ```
   This will check if services are accessible both locally and over LAN.

2. **If test shows issues, run the repair script**:
   ```bash
   sudo ./repair_services.sh
   ```
   This comprehensive script will:
   - Configure Ollama to listen on all interfaces (0.0.0.0)
   - Fix nginx configuration issues
   - Update Docker Compose configuration with proper IP addresses
   - Restart all services with the correct settings

3. **For more detailed diagnostics**:
   - Check that Ollama is listening on all interfaces:
     ```bash
     sudo systemctl status ollama
     ```
     Look for the line containing "OLLAMA_HOST=0.0.0.0:11434"

   - Verify ports are open and listening:
     ```bash
     sudo ss -tulnp | grep -E ':(3000|5000|11434)'
     ```
     You should see all three ports listening on 0.0.0.0 (all interfaces)

   - Check Docker container status:
     ```bash
     docker compose ps
     ```
     All containers should be in the "Up" state

   - Check for firewall issues:
     ```bash
     sudo iptables -L
     ```
     Ensure ports 3000, 5000, and 11434 are not being blocked

## Notes

- Dify API is accessible at http://<your-ip>:5000
- Dify Web UI is accessible at http://<your-ip>:3000
- Ollama API is accessible at http://<your-ip>:11434
- Data is persisted in the ./data directory