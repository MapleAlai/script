#!/bin/bash

PATH=/usr/bin:/bin:./../../function:./function

if ! check_root;then
    read -p "请输入 sudo 密码：" password
    export password=$password
fi

admin ls

export autoYes=$1

if ifon;then
    echo 11
fi