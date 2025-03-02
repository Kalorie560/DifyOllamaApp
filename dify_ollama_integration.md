# Dify + Ollama Integration Guide

This document explains how to integrate Dify with Ollama to create a fully local LLM application platform.

## What is Dify?

Dify is an open-source LLM application development platform that provides:
- Visual prompt engineering
- Application building without code
- API endpoints generation
- Dataset management
- Multi-model provider support

## What is Ollama?

Ollama is a local LLM runner that:
- Runs models locally on your hardware
- Supports various open-source models
- Provides a simple API for integration
- Has minimal resource requirements compared to cloud solutions

## Integration Process

### 1. Configure Ollama as a Custom Provider in Dify

1. Start both Dify and Ollama services
2. Log in to Dify admin interface at `http://<your-ip>:3000`
3. Navigate to Settings > Model Providers > Add Provider > Custom
4. Configure the provider with:
   - Name: Ollama
   - Base URL: `http://host.docker.internal:11434` (if running in Docker)
   - Chat Endpoint: `/api/chat`
   - Completion Endpoint: `/api/generate`
   - Headers: None required

### 2. Add Ollama Models to Dify

For each model in Ollama:

1. Navigate to Settings > Model Providers > Ollama > Add Model
2. Configure the model with:
   - Model Name: The exact name as in Ollama (e.g., "llama3")
   - Display Name: User-friendly name (e.g., "Llama 3")
   - Context Length: Based on model capabilities
   - Max Tokens: Based on model capabilities

### 3. Create Applications Using Ollama Models

Once configured, you can:
1. Create conversational apps or agents
2. Build text generation applications
3. Set up knowledge bases with RAG capabilities
4. Generate API endpoints for your applications

## Troubleshooting

### Common Issues

1. **Connection Errors**
   - Ensure Ollama is running
   - Verify network connectivity between Dify and Ollama
   - Check if the correct host is used (`host.docker.internal` for Docker or IP address)

2. **Model Not Found**
   - Verify the model is pulled in Ollama with `./ollama_models.py list`
   - Ensure the model name in Dify matches exactly with Ollama

3. **Performance Issues**
   - Check resource usage with `./check_status.sh`
   - Consider using smaller models if performance is slow
   - Increase RAM allocation for Docker if needed

### Testing the Integration

Use the built-in testing functionality in Dify to verify:
1. Model connectivity
2. Response generation
3. Token limits
4. Model capabilities