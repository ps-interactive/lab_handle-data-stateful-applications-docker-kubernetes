#!/bin/sh

docker-compose -f docker-compose.yml -f docker-compose-amd64.yml build --pull

docker-compose -f docker-compose.yml -f docker-compose-amd64.yml push