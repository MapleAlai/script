#!/bin/bash

path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

if ! check_root;then
    read -p "请输入 sudo 密码：" password
    export password=$password
fi

admin ls

export autoYes=$1

if ifon;then
    echo 11
fi