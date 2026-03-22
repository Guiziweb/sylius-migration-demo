#!/bin/bash
# Lance la validation selon le domaine
# Usage: validate.sh <domain> <project_dir>

DOMAIN=$1
PROJECT_DIR=$2

cd "$PROJECT_DIR" || exit 1

case "$DOMAIN" in
  composer)
    docker compose exec -T php composer validate --no-check-publish 2>&1
    ;;
  config)
    docker compose exec -T php bin/console cache:clear 2>&1
    ;;
  src)
    docker compose exec -T php bin/console cache:clear 2>&1
    ;;
  templates)
    docker compose exec -T php bin/console lint:twig templates/ 2>&1
    ;;
  frontend)
    yarn --cwd "$PROJECT_DIR" build 2>&1
    ;;
  database)
    docker compose exec -T php bin/console doctrine:schema:validate 2>&1
    ;;
  *)
    echo "Domaine inconnu: $DOMAIN"
    exit 1
    ;;
esac