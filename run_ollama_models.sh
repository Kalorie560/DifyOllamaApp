#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="$DIR/venv"

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Run the Python script with arguments
python "$DIR/ollama_models.py" "$@"
