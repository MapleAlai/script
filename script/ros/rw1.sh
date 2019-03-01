#!/bin/bash

path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

#   检查是否具有最高权限,无则提示并退出脚本.
if ! check_root;then
    read -p "请输入 sudo 密码：" password
    export password=$password
fi

read -n 1 key_var
if [ "[A" = "$key_var" ];then
echo -e "1"
fi
