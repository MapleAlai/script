#!/bin/bash
path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

if [ "remove" = "$1" ];then
  echo remove
  admin "apt remove gcc-arm-none-eabi libncurses5-dev libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib scons qemu qemu-system-arm "
  if [ "-y" = "$2" ];then
    autoYes="y"
  fi
  if [ $(ls ~| grep rt-thread) ];then
    if ifon "是否移除 rt-thread 源码?";then
      rm -rf ~/rt-thread
    fi
  fi
  if [ $(ls ~| grep .env) ];then
    if ifon "是否移除 .env 环境文件?";then
      rm -rf ~/.env
    fi
  fi
fi
if [ "-y" == "$1" ];then
  autoYes="y"
fi
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

if ! check_rely qemu-system-arm;then
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
cpu_processor=$[$(grep -c 'processor' /proc/cpuinfo) * 2]
#  编译
scons -c &> /dev/null
time1=$(date +%s%N)
result=$(scons -j$cpu_processor)
time2=$(date +%s%N)
time_ms=$[(time2 - time1) / 1000000]
echo 编译时间: $[time_ms / 1000].$[time_ms % 1000] s
success=$(echo $result | grep -A 3 -i "filename")
if [ ${#success} != 0 ];then
  echo "编译成功"
  echo $success
else
  echo $result
  err=$(echo $result | grep -lstdc++)
  if (${#err} != 0);then
    echo "该BSP启用了 C++ features, 但是你没有选择安装支持库，故此编译错误。"
    if ifon "是否需要 C++ features 支持库?";then
      app_list="libstdc++-arm-none-eabi-newlib "
    fi
  fi
  err=$(echo $result | grep crt0.o)
  if (${#err} != 0);then
    echo "可能是 libnewlib-arm-none-eabi 库没有安装成功，尝试重新安装...."
    app_list=$app_list"libnewlib-arm-none-eabi "
  fi
  if [ ${#app_list} != 0 ];then
    echo "install $app_list"
    admin "apt install -y ${app_list}"
  fi
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
if [ ! $(ls ~/.env/packages | grep packages) ];then
  scons --menuconfig
fi
if [ ! $(ls ~/.env/tools | grep scripts) ];then
  scons --menuconfig
fi

#  Windows 换行符 转 Linux 换行符
if [ $(ls ~/.env/packages | grep packages) ];then
  if ! check_rely dos2unix;then
    admin "apt install -y dos2unix"
  fi
  find ~/.env/packages/packages -name "Kconfig" | xargs dos2unix
fi

#  如果编译成功则尝试执行
if check_rely qemu-system-arm;then
  if [ ${#success} != 0 ];then
    ./qemu.sh
  fi
fi

cd $path_root
exit 0
