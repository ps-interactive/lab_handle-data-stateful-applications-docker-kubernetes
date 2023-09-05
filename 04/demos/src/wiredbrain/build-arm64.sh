#!/bin/sh

docker-compose -f docker-compose.yml -f docker-compose-arm64.yml build --pull

docker-compose -f docker-compose.yml -f docker-compose-arm64.yml push