#!/usr/bin/env bash

if [[ $# -lt 1 ]] ; then
  echo "Usage: $(basename $0) <env> [flyway args]"
  exit 1
fi

env=$1
shift

export FLYWAY_PASSWORD=$(decrypt-password.sh $(cat ../credentials.json | json "${env}.users.admin"))
export APPUSER_PASSWORD=$(decrypt-password.sh $(cat ../credentials.json | json "${env}.users.appuser"))

endpoint=$(aws rds describe-db-instances --db-instance-identifier ${env} | json DBInstances[0].Endpoint.Address)

./migrate.sh ${endpoint} "$@"

