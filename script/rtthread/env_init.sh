#!/bin/bash
path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

#  检测需要安装的软件包
app_list=""
if ! check_rely arm-none-eabi-gcc;then
  app_list=$app_list"gcc-arm-none-eabi libncurses5-dev libnewlib-arm-none-eabi "
  if ! ifon "是否需要 C++ features 支持库?";then
    app_list=$app_list"libstdc++-arm-none-eabi-newlib "
	fi
fi
 
if ! check_rely scons;then
  app_list=$app_list"scons "
fi

if ! check_rely qemu-system-arm;then
	if ! ifon "是否需要 qemu 模拟器？";then
  	app_list=$app_list"qemu qemu-system-arm "
	fi
fi

if [ $a ];then
  admin "apt install -y ${app_list}"
fi


alias python=python3
alias menuconfig="scons --menuconfig"
export RTT_EXEC_PATH=/usr/bin

cd ~
#  不断尝试获取 rt-thread 源码，直到获取成功或者被中断
while [ ! $(ls | grep rt-thread) ];do
  git clone https://gitee.com/rtthread/rt-thread.git
done
if check_rely qemu-system-arm;then
  cd rt-thread/bsp/qemu-vexpress-a9
else
  cd rt-thread/bsp/stm32/stm32f103-atk-nano
fi
#  获取cpu核心数
cpu_processor=`expr $(grep -c 'processor' /proc/cpuinfo) \* 2`
#  编译
result=$(scons -j$cpu_processor)
success=$(echo $a | grep -A 3 -i "hex filename")
if [ $success ];then
  echo "编译成功"
  echo $success
fi


shellrcfile=~/.${SHELL##*/}rc
if [ ! $(cat $shellrcfile | grep "#rtt_env_init") ];then
  echo "" >> $shellrcfile
  echo "#rtt_env_init" >> $shellrcfile
  echo "source ~/.env/env.sh" >> $shellrcfile
  echo 'alias menuconfig="scons --menuconfig"' >> $shellrcfile
  echo "alias python=python3" >> $shellrcfile
  echo "export RTT_EXEC_PATH=/usr/bin" >> $shellrcfile
  #source $shellrcfile
fi

#  尝试获取 env 环境
menuconfig

#  如果编译成功则尝试执行
if check_rely qemu-system-arm;then
  if [ $success ];then
    ./qemu.sh
  fi
fi

cd $path_root
exit 0
