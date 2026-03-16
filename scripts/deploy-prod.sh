#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Missing compose file: ${COMPOSE_FILE}"
  exit 1
fi

echo "Using compose file: ${COMPOSE_FILE}"
echo "Deploy tag: ${NEW_API_TAG:-latest}"

if [[ -f "${ENV_FILE}" ]]; then
  echo "Using optional env file: ${ENV_FILE}"
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
else
  docker compose -f "${COMPOSE_FILE}" pull
  docker compose -f "${COMPOSE_FILE}" up -d
  docker compose -f "${COMPOSE_FILE}" ps
fi
