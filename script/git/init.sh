#!/bin/bash

path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

if ! check_rely git;then
    admin "apt-get install git"
fi

read -p "请输入用户名：" user_name
read -p "请输入邮箱：" user_email

if ! ifon "是否使用用户名：$user_name ?";then
    read -p "请输入用户名：" user_name
fi

if ! ifon "是否使用邮箱：$user_email ?";then
    read -p "请输入邮箱：" user_email
fi

string_git="
[user]\n
	\tname = $user_name\n
	\temail = $user_email\n[credential]\n
    \thelper=store
"
echo -e $string_git > ~/.gitconfig