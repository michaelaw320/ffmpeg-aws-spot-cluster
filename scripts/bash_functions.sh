#!/bin/bash

function switch_role() {
    old_setting=${-//[^x]/}
    set +x
    local role=$1
    local token_file="/tmp/sts-creds.json"
    aws sts assume-role \
    --role-arn ${role} \
    --role-session-name assume-role \
    --duration-seconds 900 \
    > ${token_file}

    export AWS_ACCESS_KEY_ID=`cat ${token_file} | jq -r .Credentials.AccessKeyId`
    export AWS_SECRET_ACCESS_KEY=`cat ${token_file} | jq -r .Credentials.SecretAccessKey`
    export AWS_SESSION_TOKEN=`cat ${token_file} | jq -r .Credentials.SessionToken`

    rm -f ${token_file}
    if [[ -n "$old_setting" ]]; then set -x; else set +x; fi
}
