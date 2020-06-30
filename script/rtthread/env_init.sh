#!/bin/bash
path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

# 获取cpu核心数
cpu_processor=$[$(grep -c 'processor' /proc/cpuinfo) * 2]

# 自动确认
if [ "-y" = "$1" -o "-y" = "$2" ];then
  export autoYes="y"
fi

# 如果是移除所有环境
if [ "remove" = "$1" ];then
  Env -r "#rtt_env"
  Env -r "source ~/.env/env.sh" 
  Env -r 'alias menuconfig="scons --menuconfig && pkgs --update"'
  Env -r 'alias rtt_build="scons -j'${cpu_processor}'"'
  Env -r "alias python=python3"
  Env -r "export RTT_EXEC_PATH=/usr/bin"

  softapp="gcc-arm-none-eabi libncurses5-dev libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib scons qemu qemu-system-arm"
  echo "移除软件包: $softapp"
  admin "apt remove -y $softapp"

  if [ $(ls ~| grep rt-thread) ];then
    if ifon "是否移除 rt-thread 源码?";then
      rm -rf ~/rt-thread
    fi
  fi

  if [ $(ls -a ~| grep .env) ];then
    if ifon "是否移除 .env 环境文件?";then
      rm -rf ~/.env
    fi
  fi

  exit 0
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

if ! check_rely git;then
  app_list=$app_list"git "
fi

if ! check_rely qemu-system-arm;then
	if ifon "是否需要 qemu 模拟器？";then
  	app_list=$app_list"qemu qemu-system-arm "
	fi
fi

# 安装
if [ ${#app_list} != 0 ];then
  echo "安装软件包: $app_list"
  admin "apt install -y ${app_list}"
fi

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

# 查看是否存在 QEMU 模拟器，如果存在就进入模拟器的BSP文件夹
if check_rely qemu-system-arm;then
  cd rt-thread/bsp/qemu-vexpress-a9
else
  cd rt-thread/bsp/stm32/stm32f103-atk-nano
fi

#  编译
alias python=python3
export RTT_EXEC_PATH=/usr/bin
# 清除上次编译结果, 无论上次是否编译过
scons -c &> /dev/null
# 记录编译时间
time1=$(date +%s%N)
result=$(scons -j$cpu_processor)
time2=$(date +%s%N)
# 由 ns 转成 ms
time_ms=$[(time2 - time1) / 1000000]
echo
echo ----------------------------------------------------
echo 
echo 编译时间: $[time_ms / 1000].$[time_ms % 1000] s
success=$(echo "${result}" | grep -A 1 -i "filename")
if [ ${#success} != 0 ];then
  echo "编译成功"
  echo "${success}"
else
  echo "${result}"
  err=$(echo "${result}" | grep "-lstdc++")
  if (${#err} != 0);then
    echo "该BSP启用了 C++ features, 但是你没有选择安装支持库，故此编译错误。"
    if ifon "是否需要 C++ features 支持库?";then
      app_list="libstdc++-arm-none-eabi-newlib "
    fi
  fi
  err=$(echo "${result}" | grep "crt0.o")
  if (${#err} != 0);then
    echo "可能是 libnewlib-arm-none-eabi 库没有安装成功，尝试重新安装...."
    app_list=$app_list"libnewlib-arm-none-eabi "
  fi
  if [ ${#app_list} != 0 ];then
    echo "install $app_list"
    admin "apt install -y ${app_list}"
  fi
fi
echo
echo ----------------------------------------------------
echo 

# 添加环境变量
if Env "#rtt_env";then
  Env "source ~/.env/env.sh" 
  Env 'alias menuconfig="scons --menuconfig && pkgs --update"'
  Env 'alias rtt_build="scons -j'${cpu_processor}'"'
  Env "alias python=python3"
  Env "export RTT_EXEC_PATH=/usr/bin"
  Env
fi

#  尝试获取 .env 环境
if [ ! $(ls -a ~/| grep .env) ];then
  scons --menuconfig
fi
if [ ! $(ls -a ~/.env/packages | grep packages) ];then
  scons --menuconfig
fi
if [ ! $(ls -a ~/.env/tools | grep scripts) ];then
  scons --menuconfig
fi

#  Windows 换行符 转 Linux 换行符
if [ $(ls -a ~/.env/packages | grep packages) ];then
  if ! check_rely dos2unix;then
    admin "apt install -y dos2unix"
  fi
  echo 转换格式成Unix格式......
  find ~/.env/packages/packages -name "Kconfig" | xargs dos2unix &> /dev/null
fi

#  如果编译成功则尝试执行
if check_rely qemu-system-arm;then
  if [ ${#success} != 0 ];then
    ./qemu.sh
  fi
fi

cd $path_root
exit 0
