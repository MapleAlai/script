#!/bin/bash

PATH=/usr/bin:/bin:./../../function:./function

#   检查是否具有最高权限,无则提示并退出脚本.
if ! check_root;then
 read -p "请输入 sudo 密码：" password
fi

#   获取执行脚本的用户
Who=$(whoami)

#   是否全部自动输入 y
autoYes="n"
if [ -n "$1" ]; then
    if [ "$1" = "-y" ]; then
        autoYes="y"
    fi
fi

#   往 ~/.bashrc 中写入 函数接收的第一个参数 ( 如果不存在的话 )
echo_bashrc(){
    if [ ! "$1" ];then
	    return 1
    else
        if [ ! "$(cat ~/.bashrc | grep "$1")" ];then
            echo $1 >> ~/.bashrc
        fi
    fi
    return 0
}

#    if ifon "是否更换apt源为阿里云源？" ; then
#        echo "更换 apt源 为阿里云......"
#        sudo sh -c 'echo "
#        deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse
#        deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse
#        deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse
#        deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-proposed main restricted universe multiverse
#        deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse
#        deb-src http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse
#        deb-src http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse
#        deb-src http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse
#        deb-src http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-proposed main restricted universe multiverse
#        deb-src http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse
#        " > /etc/apt/sources.list.d/aliyun-ubuntu.list'
#    fi


    if [ $(lsb_release -si) = "Ubuntu" ]; then
        os_release=$(lsb_release -rs)
        if [ $os_release = "16.04" ]; then
            rosversion="kinetic"
        elif [ $os_release = "18.04" ]; then
            rosversion="melodic"
        else
            echo "系统版本不符合,请使用 16.04 / 18.04 LTS 版本！"
            exit 1
        fi
    else
        echo "系统不符合,请使用 Ubuntu 系统！"
        exit 1
    fi
    
    echo
    echo
if ifon "是否安装ROS？";then
    echo "开始安装ROS：$rosversion"
    
    sudo sh -c 'echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    
    admin "apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116"
    
    admin "apt-get update" && admin "apt-get upgrade -y"
    
    admin "apt-get -y install ros-$rosversion-desktop-full"
    
    admin "apt-get -y install ros-$rosversion-rqt*"
    
    admin "rosdep init && sudo -u $Who rosdep update -y"
    
    echo_bashrc "source /opt/ros/$rosversion/setup.bash"
    source /opt/ros/$rosversion/setup.bash
    
    admin "apt-get -y install python-rosinstall python-rosinstall-generator python-wstool build-essential"

    admin "apt-get -y install ros-$rosversion-gazebo-ros ros-$rosversion-gmapping ros-$rosversion-slam-karto ros-$rosversion-amcl ros-$rosversion-move-base ros-$rosversion-map-server ros-$rosversion-dwa-local-planner ros-$rosversion-hector-mapping"
    
    echo "ROS安装过程已结束，请自行检查......"
fi

    if ifon "是否创建工作目录？";then
        read -p "请输入工作目录名：" Dirname
        sudo -u $Who mkdir -p ~/$Dirname/src

        if ifon "是否克隆ROS-Academy-for-Beginners项目到src目录中?";then
            echo "克隆 ROS-Academy-for-Beginners 项目到src目录中......"
            cd ~/$Dirname/src
            sudo -u $Who git clone https://github.com/DroidAITech/ROS-Academy-for-Beginners.git
            cd ~/$Dirname
            sudo -u $Who rosdep install --from-paths src --ignore-src --rosdistro=$rosversion -y
            echo_bashrc "source ~/$Dirname/devel/setup.bash"
        fi
        
        cd ~/$Dirname
        #sudo -u $Who /opt/ros/$rosversion/bin/catkin_make
        sudo -u $Who catkin_make
        source ~/$Dirname/devel/setup.bash
    
    fi

    if ifon "是否测试运行代码? ";then
        roslaunch robot_sim_demo robot_spawn.launch
    fi

echo
echo
echo "请执行"
echo -e "\tsource ~/.bashrc"
echo "或重启一个终端"

exit 0
