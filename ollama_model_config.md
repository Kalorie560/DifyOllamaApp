# Configuring Ollama Models in Dify

This guide explains how to add your Ollama models as custom providers in Dify.

## Basic Configuration

For each model in Ollama, you'll need to create a separate custom provider in Dify. Here's what you'll need:

1. **Provider Name**: A descriptive name like "Ollama-QwenSmall"
2. **Base URL**: `http://host.docker.internal:11434`
3. **Chat Endpoint**: `/api/chat`
4. **Completion Endpoint**: `/api/generate`
5. **Model Name**: Exactly as it appears in Ollama (e.g., `qwen:0.5b`)

## Step-by-Step Instructions

1. Log in to Dify at http://YOUR_IP
2. Navigate to Settings > Model Providers
3. Click "Add Provider"
4. Select "Custom" from the dropdown
5. Fill in the form:
   - Provider Name: "Ollama-ModelName" (e.g., "Ollama-Qwen")
   - Base URL: `http://host.docker.internal:11434`
   - Headers: (leave empty)
   - Chat Completion Endpoint: `/api/chat`
   - Text Completion Endpoint: `/api/generate`
   - Parameters:
     - Model Name: The exact name from Ollama (e.g., `qwen:0.5b`)
     - You can adjust max_tokens and other parameters as needed
6. Click "Test" to verify the connection works
7. Save the provider

## Sample Configurations

### For qwen:0.5b

```json
{
  "provider": "custom",
  "model_name": "qwen:0.5b",
  "chat_endpoint": "/api/chat",
  "completion_endpoint": "/api/generate",
  "parameters": {
    "context_size": 2048,
    "max_tokens": 1024
  }
}
```

### For deepseek-r1:8b

```json
{
  "provider": "custom",
  "model_name": "deepseek-r1:8b",
  "chat_endpoint": "/api/chat",
  "completion_endpoint": "/api/generate",
  "parameters": {
    "context_size": 4096,
    "max_tokens": 2048
  }
}
```

## Troubleshooting

If the "Test" button fails:

1. Ensure Ollama is running locally (`ollama serve`)
2. Verify the model name exactly matches what's in Ollama
3. Check if Docker can access your host machine's services
4. Try using your machine's IP instead of `host.docker.internal` if needed
5. Check Dify logs for more specific error messages