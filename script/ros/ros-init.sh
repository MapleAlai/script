#!/bin/bash

path_root=$(pwd)
PATH=/usr/bin:/bin:$path_root/../../function:$path_root/function:$path_root

#   检查是否具有最高权限,无则提示并退出脚本.
if ! check_root;then
    read -p "请输入 sudo 密码：" password
    export password=$password
fi

#   获取执行脚本的用户
export Who=$(whoami)

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
        if [ ! "$(cat ~/.*shrc | grep "$1")" ];then
            echo $1 >> ~/.*shrc
        fi
    fi
    return 0
}

#    if ifon "是否更换apt源为阿里云源？" ; then
#        echo "更换 apt源 为阿里云......"
#        echo $password | sudo -S sh -c 'echo "
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
    
    echo $password | sudo -S sh -c 'echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    
    admin apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
    
    admin apt-get update && admin apt-get upgrade -y
    
    admin apt-get -y install ros-$rosversion-desktop-full
    
    admin apt-get -y install ros-$rosversion-rqt*
    
    admin rosdep init
    
    user rosdep update -y
    
    echo_bashrc "source /opt/ros/$rosversion/setup.sh"
    source /opt/ros/$rosversion/setup.sh
    
    admin apt-get -y install python-rosinstall python-rosinstall-generator python-wstool build-essential
    
    echo -e "\n更改 /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2.so 为 cv2_ros.so"
    admin mv /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2.so /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2_ros.so

    echo "ROS安装过程已结束，请自行检查......"
fi

    if ifon "是否创建工作目录？";then
        read -p "请输入工作目录名：" Dirname
        source ~/.bashrc
        user mkdir -p ~/$Dirname/src

        if ifon "是否克隆ROS-Academy-for-Beginners项目到src目录中?";then
            echo "克隆 ROS-Academy-for-Beginners 项目到src目录中......"
            cd ~/$Dirname/src
            user git clone https://github.com/DroidAITech/ROS-Academy-for-Beginners.git
            cd ~/$Dirname
            user rosdep install --from-paths src --ignore-src --rosdistro=$rosversion -y
            echo_bashrc "source ~/$Dirname/devel/setup.sh"
            admin "apt-get -y install ros-$rosversion-gazebo-ros ros-$rosversion-gmapping ros-$rosversion-slam-karto ros-$rosversion-amcl ros-$rosversion-move-base ros-$rosversion-map-server ros-$rosversion-dwa-local-planner ros-$rosversion-hector-mapping"
        fi
        
        cd ~/$Dirname
        #user /opt/ros/$rosversion/bin/catkin_make
        user catkin_make
        source ~/$Dirname/devel/setup.sh

    fi
    
    if ifon "是否更新Gazebo?";then
        admin sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
        wget http://packages.osrfoundation.org/gazebo.key -O - | admin apt-key add -
        admin apt-get update
        admin apt-get install gazebo7
    fi

    if ifon "是否测试运行代码?";then
        source ~/.bashrc
        roslaunch robot_sim_demo robot_spawn.launch
        rosrun image_view image_view image:=/camera/depth/image_raw
        rosrun image_view image_view image:=/camera/rgb/image_raw
        rosrun robot_sim_demo robot_keyboard_teleop.py
    fi

    if ifon "是否安装CUDA_Toolkit?";then
        if ! check_rely axel;then
            admin apt-get -y install axel
        fi

        filename="cudaToolKitNetworkInstall.deb"
        fileURL="https://developer.download.nvidia.cn/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb"
        axel -n 10 -o $filename $fileURL
        echo
        admin dpkg -i $filename
        admin apt-get update
        admin apt-get install -y cuda
        echo_bashrc 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"'
        rm $filename

        if ifon "是否测试?";then
            cd /usr/local/cuda-8.0/samples/1_Utilities/deviceQuery
            sudo make
            sudo ./deviceQuery
        fi
    fi

    if ifon "是否安装cuDNN-v5.1?";then
        if ! check_rely tar;then
            admin apt-get -y install tar
        fi

        echo -e "\n请手动下载.tzg文件，URL:"
        echo -e "\thttps://blog.csdn.net/sunmingliu/article/details/79763929"
        echo -e "\n将它放在 $(pwd) 目录下。"
        if ifon "是否完整？";then
            admin tar -xzvf cudnn-8.0-linux-x64-v5.1.tgz 

            admin cp cuda/include/cudnn.h /usr/local/cuda/include 

            admin cp cuda/lib64/libcudnn* /usr/local/cuda/lib64 
            
            admin chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*

            admin cat /usr/local/cuda/include/cudnn.h | grep CUDNN_MAJOR -A2  
        fi

        echo_bashrc 'export CUDA_HOME=/usr/local/cuda'
    fi

    if ifon "是否安装TensorFlow-GPU(1.2)?";then
        if ! check_rely python3;then
            admin apt-get -y install python3-dev
        fi

        admin python3 -m pip install tensorflow-gpu==1.2

        if ifon "是否测试Tensorflow-GPU？";then
            git clone https://github.com/tensorflow/models.git

            cd models/tutorials/image/mnist
            python convolutional.py
        fi
    fi

    if ifon "是否安装SSD框架？";then
        if ! check_rely git;then
            admin apt-get -y install git
        fi
        git clone https://github.com/weiliu89/caffe.git
        cd caffe
        git checkout ssd

        cp Makefile.config.example Makefile.config
        make -j8
        make py
        make test -j8
        make runtest -j8

    fi
    https://blog.csdn.net/xinyuanjoe/article/details/78679884
exit 0
