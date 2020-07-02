# script：一键脚本

> **在 script 目录中存放各种环境初始化文件**



### ros/ros-init.sh	——	 ros 系统一键安装脚本，支持16.04LTS和18.04LTS

```bash
bash script/ros/ros-init.sh

		or

cd script/ros && bash ros-init.sh
```

### rtthread/env-init.sh	——	 RT-Thread 系统编译环境一键安装脚本

> **已测试环境：armbian(focal,rk3399) deepin(20,pc) ubuntu(focal,pc)**

> **安装如下软件: gcc-arm-none-eabi libncurses5-dev libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib scons qemu qemu-system-arm dos2unix**

> **添加如下指令: menuconfig(结束后默认pkgs --update) rtt_build(默认使用 CPU*2 编译) rtt_clear(静默，不输出过程信息)**

```bash
#	安装
bash script/rtthread/env-init.sh -y

		or

cd script/rtthread && bash env-init.sh -y

#	移除
bash script/rtthread/env-init.sh remove -y

		or

cd script/rtthread && bash env-init.sh remove -y
```

