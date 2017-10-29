#!/usr/bin/env bash

set -e

if [[ -z "$POSTGRES_DEFAULT_USER" || -z "$POSTGRES_DEFAULT_PASS" ]]
then
    eval $(sed -r 's/^(POSTGRES_DEFAULT_.*) DEFAULT/export \1/' /etc/security/pam_env.conf | grep POSTGRES_DEFAULT_)
fi
