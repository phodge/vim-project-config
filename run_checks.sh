#!/usr/bin/env bash
set -e
poetry install --no-root
poetry run mypy tests && echo "MYPY OK"
poetry run flake8 tests && echo "flake8 OK"
poetry run pytest tests && echo "pytest OK"
