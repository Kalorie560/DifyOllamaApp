# DifyOllamaApp Development Guidelines

## Commands
- Initial setup: `./setup.sh`
- Start services: `./start_app.sh`
- Stop services: `./stop_app.sh`
- Check status: `./check_status.sh`
- List Ollama models: `python ollama_models.py list`
- Pull new Ollama model: `ollama pull model_name`
- Run tests: `pytest -xvs tests/`
- Check logs: `docker-compose logs -f [service_name]`

## Code Style
- **Imports**: Standard library first, third-party next, local modules last
- **Naming**: snake_case for functions/variables, CamelCase for classes, UPPER_CASE for constants
- **Types**: Use type hints for all functions and method signatures
- **Docker**: Keep Dockerfiles clean with minimal layers
- **Error Handling**: Graceful failure with informative error messages
- **Config**: Use YAML for configuration, environment variables for secrets
- **Comments**: Docstrings for all functions/classes, inline comments for complex logic
- **Network**: Always bind to 0.0.0.0 for network services with configurable port
- **Security**: Never hardcode credentials, validate all external inputs