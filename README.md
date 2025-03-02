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
   - Base URL: http://host.docker.internal:11434
   - Chat Endpoint: /api/chat
   - Completion Endpoint: /api/generate
   - Model Name: Use the exact name from Ollama (e.g., qwen:0.5b)

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

## Notes

- Dify API is accessible at http://<your-ip>:5000
- Dify Web UI is accessible at http://<your-ip>:3000
- Ollama API is accessible at http://<your-ip>:11434
- Data is persisted in the ./data directory