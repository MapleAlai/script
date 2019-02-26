#!/bin/bash

PATH=/usr/bin:/bin:./../../function:./function

#   检查是否具有最高权限,无则提示并退出脚本.
if ! check_root;then
    read -p "请输入 sudo 密码：" password
    export password=$password
fi

if ifon "是否安装搜狗输入法？";then
    if ! check_rely axel;then
        admin apt-get -y install axel
    fi

    filename="sogoupinyin.deb"
    axel -n 10 -o $filename http://cdn2.ime.sogou.com/dl/index/1524572264/sogoupinyin_2.2.0.0108_amd64.deb?st=huXGNesQzlTdJ5MzBinzMg&e=1551065264&fn=sogoupinyin_2.2.0.0108_amd64.deb
    echo
    echo
    admin dpkg -i $filename
    admin apt-get install -y -f

    rm $filename
fi

if ifon "是否安装 vsCode？";then
    if ! check_rely axel;then
        admin apt-get -y install axel
    fi

    filename="vscode.deb"
    axel -n 10 -o vscode.deb https://vscode.cdn.azure.cn/stable/1b8e8302e405050205e69b59abb3559592bb9e60/code_1.31.1-1549938243_amd64.deb
    echo
    echo
    admin dpkg -i $filename
    admin apt-get install -y -f

    rm $filename
fi

