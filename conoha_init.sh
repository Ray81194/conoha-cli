#!/bin/bash

INI_FILE=ini.ini
SERVER_FILE=server.json

conoha_init()
{
    read_ini

    local ex=($token_expires)
    local d=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $ex)
    local ds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $ex +%s)
    local now=$(date +%s)

    if [[ ds -lt now ]]; then
        echo token old
        conoha_token
        read_ini
    fi
}

conoha_token()
{
    echo get token
    local tmp=$(curl -X POST \
        -H "Accept: application/json" \
        -d '{"auth":{"passwordCredentials":{"username":"'$username'","password":"'$password'"},"tenantId":"'$tenantId'"}}' \
        https://identity.tyo1.conoha.io/v2.0/tokens -w '\n%{http_code}' -s)

    local res=$(echo "$tmp" | sed '$d')
    local res_code=$(echo "$tmp" | tail -n 1)

    if [[ $res_code != 200 ]]; then
        echo error httpstatus=$res_code
        exit 1
    fi

    local token=$(echo $res | jq ".access.token")
    local new_token_expires=$(echo $token | jq -r ".expires")
    local new_token_issued_at=$(echo $token | jq -r ".issued_at")
    local new_token_user_token=$(echo $token | jq -r ".id")

    sed -i -e "s/token_expires=\(.*\)/token_expires=$new_token_expires/g" ini.ini
    sed -i -e "s/token_issued_at=\(.*\)/token_issued_at=$new_token_issued_at/g" ini.ini
    sed -i -e "s/token_user_token=\(.*\)/token_user_token=$new_token_user_token/g" ini.ini
}

read_ini()
{
    if [[ ! -f $INI_FILE ]]; then
        echo ini not exists
        exit 1
    fi

    . $INI_FILE

    USER_TOKEN=$(echo $token_user_token)
    TENANT_ID=$(echo $auth_tenant_id)
    username=$(echo $auth_username)
    password=$(echo $auth_password)
    tenantId=$(echo $TENANT_ID)
    SSH_PRIVATE_KEY=$(echo $ssh_path)
}
