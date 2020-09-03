#!/usr/bin/env bash

export FLYWAY_PASSWORD=Welcome123
export APPUSER_PASSWORD=Password1

# Because the Docker MySQL uses a self signed cert
export SSL_MODE=REQUIRED

./migrate.sh "$@"
