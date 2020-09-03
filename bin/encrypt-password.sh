#!/usr/bin/env bash

#
# Make sure you set the Key ID
#
# $ KEY_ID=alias/thealias ./encrypt-password the_string_I_want_to_encrypt
#

if [[ "${KEY_ID}" = "" ]] ; then
	echo "Error: \$KEY_ID not set; exiting."
	exit 1
fi

if [[ $# -lt 1 ]] ; then
  echo "Usage: $(basename $0) <string>"
  exit 1
fi

aws kms encrypt --key-id $KEY_ID --plaintext "$1" --query CiphertextBlob --output text
