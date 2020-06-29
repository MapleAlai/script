#!/bin/bash
path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

#  检测需要安装的软件包
app_list=""
if ! check_rely arm-none-eabi-gcc;then
  app_list=$app_list"gcc-arm-none-eabi libncurses5-dev libnewlib-arm-none-eabi "
  if ifon "是否需要 C++ features 支持库?";then
    app_list=$app_list"libstdc++-arm-none-eabi-newlib "
	fi
fi
 
if ! check_rely scons;then
  app_list=$app_list"scons "
fi

if check_rely qemu-system-arm;then
	if ifon "是否需要 qemu 模拟器？";then
  	app_list=$app_list"qemu qemu-system-arm "
	fi
fi
# 安装
if [ ${#app_list} != 0 ];then
  echo "install $app_list"
  admin "apt install -y ${app_list}"
fi


alias python=python3
export RTT_EXEC_PATH=/usr/bin

cd ~
#  不断尝试获取 rt-thread 源码，直到获取成功或者被中断
while [ ! $(ls | grep rt-thread) ];do
  ping -c 1 www.google.com &> /dev/null
  if [ -n $? ];then
    git clone https://github.com/rtthread/rt-thread.git
  else
    git clone https://gitee.com/rtthread/rt-thread.git
    sed -i 's/gitee.com/github.com/g' rt-thread/.git/config
  fi
done
if check_rely qemu-system-arm;then
  cd rt-thread/bsp/qemu-vexpress-a9
else
  cd rt-thread/bsp/stm32/stm32f103-atk-nano
fi
#  获取cpu核心数
cpu_processor=`expr $(grep -c 'processor' /proc/cpuinfo) \* 2`
#  编译
result=$(scons -c && scons -j$cpu_processor)
success=$(echo $result | grep -A 3 -i "filename")
if [ ${#success} != 0 ];then
  echo "编译成功"
  echo $success
else
  echo $result
fi


if add_env "#rtt_env_init";then
  echo "添加环境变量"
  add_env "source ~/.env/env.sh" 
  add_env 'alias menuconfig="scons --menuconfig && pkgs --update"'
  add_env 'alias rtt_build="scons -j'${cpu_processor}'"'
  add_env "alias python=python3"
  add_env "export RTT_EXEC_PATH=/usr/bin"
  add_env
fi

#  尝试获取 env 环境
if [ ! $(ls ~/| grep .env) ];then
  scons --menuconfig
fi
if [ ! $(ls ~/.env/packages/packages) ];then
  scons --menuconfig
fi
if [ ! $(ls ~/.env/tools/scripts) ];then
  scons --menuconfig
fi

#  如果编译成功则尝试执行
if check_rely qemu-system-arm;then
  if [ ${#success} != 0 ];then
    ./qemu.sh
  fi
fi

cd $path_root
exit 0
