#!/bin/bash

PATH=/usr/bin:/bin:./../../function:./function

#   检查是否具有最高权限,无则提示并退出脚本.
if ! check_root 0;then
 read -p "请输入 sudo 密码：" password
fi

if ifon "是否安装搜狗输入法？";then
    if check_rely axel;then
        admin "apt-get -y install axel"
    fi
    axel -n 10 -o sogoupinyin.deb http://cdn2.ime.sogou.com/dl/index/1524572264/sogoupinyin_2.2.0.0108_amd64.deb?st=huXGNesQzlTdJ5MzBinzMg&e=1551065264&fn=sogoupinyin_2.2.0.0108_amd64.deb
    admin "dpkg -i sogoupinyin.deb"
    admin "apt-get install -f"
fi

