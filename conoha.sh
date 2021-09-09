#!/bin/bash

. conoha_init.sh
. conoha_body.sh

sub_command=

case "$1" in
    init | list | ls | up | del | ssh)
        sub_command=$1
        shift
        ;;
    -h)
        echo help
        exit 0
        ;;
    *)
        echo unknown command
        exit 1
        ;;
esac

conoha_init

result=0

if [[ $sub_command == init ]]; then
    echo init
    result=$?
elif [[ $sub_command == list || $sub_command == ls ]]; then
    conoha_list
    result=$?

elif [[ $sub_command == up ]]; then
    conoha_up
    result=$?

elif [[ $sub_command == del ]]; then
    conoha_del
    result=$?

elif [[ $sub_command == ssh ]]; then
    conoha_ssh
    result=$?

fi

exit "$result"
  

