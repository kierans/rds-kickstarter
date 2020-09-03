#!/usr/bin/env bash

if [[ $# -lt 1 ]] ; then
  echo "Usage: $(basename $0) <host> <options>"
  exit 1
fi

if [[ "${FLYWAY_PASSWORD}" = "" ]] ; then
	echo "Error: \$FLYWAY_PASSWORD not set; exiting."
	exit 1
fi

if [[ "${APPUSER_PASSWORD}" = "" ]] ; then
	echo "Error: \$APPUSER_PASSWORD not set; exiting."
	exit 1
fi

HOST=$1
shift

echo "Migrating ${HOST}"

docker run \
  --rm \
  --network=rds-mysql-local-network \
	-v $(pwd)/../sql/migrations:/flyway/sql/ \
	-e RDS_HOST=${HOST} \
	-e SSL_MODE=${SSL_MODE} \
	-e FLYWAY_PASSWORD=${FLYWAY_PASSWORD} \
	-e FLYWAY_PLACEHOLDERS_ROOT_PASSWORD=${FLYWAY_PASSWORD} \
	-e FLYWAY_PLACEHOLDERS_APPUSER_PASSWORD=${APPUSER_PASSWORD} \
	kierans777/flyway-mysql-rds:1.1.0 "$@" migrate
