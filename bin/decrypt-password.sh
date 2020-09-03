#!/usr/bin/env bash

# Note this wont work if you don't have the correct IAM access

if [[ $# -lt 1 ]] ; then
  echo "Usage: $(basename $0) <base64 string>"
  exit 1
fi

aws kms decrypt --ciphertext-blob fileb://<(echo "$1" | base64 -d) --output text --query Plaintext | base64 -d

# Add a newline
echo
