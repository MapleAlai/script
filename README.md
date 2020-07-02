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

