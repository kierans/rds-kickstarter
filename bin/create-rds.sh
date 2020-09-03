#!/usr/bin/env bash

#
# Simple RDS creation script
#
# For full options, including how to have the RDS encrypted see the docs and the CLI help
#
# See https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.MySQL.html
# See `aws rds help`
#

if [[ $# -lt 1 ]] ; then
  echo "Usage $(basename $0): <db instance name>"
  exit 1
fi

dbInstanceName=$1
password=$(./decrypt-password.sh $(cat ../credentials.json | json "${dbInstanceName}.users.admin"))

aws rds create-db-instance \
   --engine "mysql" \
   --engine-version "8.0.16" \
   --db-instance-identifier "${dbInstanceName}" \
   --master-username "root" \
   --master-user-password "${password}" \
   --db-instance-class "db.t3.micro" \
   --storage-type "gp2" \
   --allocated-storage 20 \
   --no-multi-az \
   --publicly-accessible \
   --port 3306 \
   --auto-minor-version-upgrade \
   --deletion-protection
