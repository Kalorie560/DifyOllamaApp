#!/usr/bin/env python3
import argparse
import requests
import sys
import json
import os

OLLAMA_API_HOST = os.environ.get("OLLAMA_API_HOST", "http://localhost:11434")

def check_ollama_running():
    """Check if Ollama service is running."""
    try:
        response = requests.get(f"{OLLAMA_API_HOST}/api/tags", timeout=2)
        return response.status_code == 200
    except requests.exceptions.ConnectionError:
        print("❌ Ollama service is not running")
        print("   To start Ollama, run: ollama serve")
        return False
    except Exception as e:
        print(f"❌ Error checking if Ollama is running: {e}")
        return False

def list_models():
    """List all available models in Ollama."""
    if not check_ollama_running():
        return

    try:
        response = requests.get(f"{OLLAMA_API_HOST}/api/tags")
        if response.status_code == 200:
            data = response.json()
            models = data.get('models', [])
            
            if not models:
                print("No models found in Ollama.")
                print("You can pull models with: ollama pull model_name")
                return
                
            print(f"Found {len(models)} models:")
            for model in models:
                name = model.get('name', 'Unknown')
                size = model.get('size', 0) / (1024 * 1024 * 1024)  # Convert to GB
                modified = model.get('modified', 'Unknown')
                print(f"- {name:20} Size: {size:.2f} GB  Modified: {modified}")
        else:
            print(f"Error: Ollama API returned status code {response.status_code}")
    except Exception as e:
        print(f"Error listing models: {e}")

def pull_model(model_name):
    """Pull a model from Ollama."""
    if not check_ollama_running():
        return

    print(f"Pulling model: {model_name}")
    print("This may take a while depending on the model size...")
    
    try:
        # For simplicity, we'll use os.system instead of streaming the API response
        os.system(f"ollama pull {model_name}")
        print(f"Successfully pulled model: {model_name}")
    except Exception as e:
        print(f"Error pulling model: {e}")

def get_dify_custom_provider_config(model_name):
    """Generate configuration for adding the model as a custom provider in Dify."""
    base_url = OLLAMA_API_HOST.replace("localhost", "host.docker.internal")
    
    config = {
        "provider": "custom",
        "model_name": model_name,
        "chat_endpoint": f"{base_url}/api/chat",
        "completion_endpoint": f"{base_url}/api/generate",
        "parameters": {
            "context_size": 4096,
            "max_tokens": 2048
        }
    }
    
    print("\nTo add this model to Dify as a custom provider, use these settings:")
    print(json.dumps(config, indent=2))
    print("\nIn Dify web interface:")
    print("1. Go to Settings > Model Providers > Add Provider > Custom")
    print("2. Fill in the details above")
    print("3. Test the connection and save")

def main():
    parser = argparse.ArgumentParser(description="Ollama Models Manager")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List available models")
    
    # Pull command
    pull_parser = subparsers.add_parser("pull", help="Pull a model from Ollama")
    pull_parser.add_argument("model_name", help="Name of the model to pull")
    
    # Configure command
    config_parser = subparsers.add_parser("config", help="Get Dify configuration for a model")
    config_parser.add_argument("model_name", help="Name of the model to configure")
    
    args = parser.parse_args()
    
    if args.command == "list":
        list_models()
    elif args.command == "pull":
        pull_model(args.model_name)
    elif args.command == "config":
        get_dify_custom_provider_config(args.model_name)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
