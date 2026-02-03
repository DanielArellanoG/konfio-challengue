#!/bin/bash
set -e # Exit on error ($? != 0)

DOCKER_USER=danarellanog
TAG=latest

services=(
  "loan-api"
  "auth-service"
  "scoring-service"
)

for svc in "${services[@]}"; do
  echo "Building $svc"
  docker build -t $DOCKER_USER/$svc:$TAG ./services/$svc

  echo "Pushing $svc"
  docker push $DOCKER_USER/$svc:$TAG
done
