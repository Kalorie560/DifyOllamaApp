#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Stopping Dify with Ollama integration..."
docker compose down

echo "Services stopped successfully."
