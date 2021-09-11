#!/bin/bash

INI_FILE=conoha.ini
INI_NAME_LIST=(auth_username auth_password auth_tenant_id token_user_token token_issued_at token_expires ssh_path)
SERVER_FILE=server.json

conoha_init()
{
    if [[ -f $INI_FILE ]]; then
        load_ini

        # ファイルフォーマット（行数）が異なる場合作り直しのため削除
        if [[ $(grep -cv '^$' $INI_FILE) != 7 ]]; then
            echo not ini format
            rm $INI_FILE
        fi
    fi

    # ファイルがない場合作成
    if [[ ! -f $INI_FILE ]]; then
        echo make ini file
        touch $INI_FILE
        echo -e "auth_username=\nauth_password=\nauth_tenant_id=\ntoken_user_token=\ntoken_issued_at=\ntoken_expires=\nssh_path=" > $INI_FILE
    fi

    # value更新
    for ini_name in ${INI_NAME_LIST[@]}
    do
        local ini_val=$(eval echo '$'$ini_name)
        case "$ini_name" in auth_username | auth_password | auth_tenant_id | ssh_path)
                if [[ -z $ini_val ]]; then
                    read -p $ini_name: new_ini_val
                    ini_val=$(echo $new_ini_val)
                fi
        esac

        sed_edit $ini_name $ini_val
    done
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

    sed_edit token_expires $new_token_expires
    sed_edit token_issued_at $new_token_issued_at
    sed_edit token_user_token $new_token_user_token
}

init()
{
    load_ini

    local ds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $token_expires +%s 2> /dev/null)
    local now=$(date +%s)

    if [[ ds -lt now ]]; then
        echo token old
        conoha_token
        load_ini
    fi
}

load_ini()
{
    if [[ ! -f $INI_FILE ]]; then
        echo ini file not exists
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

sed_edit()
{
    #echo '$1: ' $1
    #echo '$2: ' $2

    sed -i '' -e "$(echo s $1=.* $1=$2 g)" $INI_FILE
}
