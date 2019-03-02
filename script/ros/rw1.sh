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

install_ros(){
    echo "开始安装ROS：$rosversion"
    
    echo $password | sudo -S sh -c 'echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    
    admin apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
    
    admin apt-get update && admin apt-get upgrade -y
    
    admin apt-get -y install ros-$rosversion-desktop-full
    
    admin apt-get -y install ros-$rosversion-rqt*
    
    admin rosdep init
    
    user rosdep update -y
    
    echo_bashrc "source /opt/ros/$rosversion/setup.sh"
    
    admin apt-get -y install python-rosinstall python-rosinstall-generator python-wstool build-essential
    
    echo -e "\n更改 /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2.so 为 cv2_ros.so"
    admin mv /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2.so /opt/ros/$rosversion/lib/python2.7/dist-packages/cv2_ros.so

    echo "ROS安装过程已结束，请自行检查......"
    source /opt/ros/$rosversion/setup.sh
}

ros_dir="~";

install_ralidar_driver(){
    cd $ros_dir/src
    git clone https://github.com/Slamtec/rplidar_ros.git
    cd ..
    catkin_make
    echo "相关信息请到官网查看：http://wiki.ros.org/rplidar"
}

make_ros_dir(){
    read -p "请输入工作目录名：" Dirname
    ros_dir="$ros_dir/$Dirname"
    user mkdir -p $ros_dir/src

    cd $ros_dir
    catkin_make
    echo_bashrc "source $ros_dir/devel/setup.sh"
    source $ros_dir/devel/setup.sh
}

install_tensorflow(){
    if ifon "是否安装指定版本显卡驱动？";then
        echo "请到 http://www.nvidia.com/Download/index.aspx?lang=en-us 检查驱动版本。"
        echo "5s 后刷新 apt软件包列表....."
        sleep 5
        admin add-apt-repository ppa:graphics-drivers/ppa
        admin apt-get update  

        read -p "请输入驱动版本：" driver_version
        admin apt-get install nvidia-$driver_version
        sudo apt-get install mesa-common-dev  
        sudo apt-get install freeglut3-dev

        echo "5s 之后重启检测"
        commond="
            nvidia-smi
            if $?;then

            fi
        "
    fi

    echo "请到 https://developer.nvidia.com/cuda-downloads 下载需求版本的 cuda (后缀为run)"
    echo "下载好后，复制到 ~/script_install 目录下，并改名为cuda_install_[1|2|3|...].run"

    if ifon "是否继续？";then
        cd ~/script_install
        sudo sh *.run <<EOF
q
accept
n
y

y
y

EOF

    echo_bashrc "
export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
"
    source ~/.bashrc

    cd /usr/local/cuda-8.0/samples/1_Utilities/deviceQuery
    sudo make
    sudo ./deviceQuery

    fi

    echo "请到 https://developer.nvidia.com/rdp/cudnn-download 下载相对应版本的 cuDNN"
    echo "并把它放到 ~/script_install 下并改名为cudnn.tgz"

    if ifon "是否继续？";then
        cd ~/script_install
        tar zxvf cudnn.tgz
        sudo cp cuda/include/cudnn.h /usr/local/cuda/include/
        cd cuda/lib64/
        sudo cp lib* /usr/local/cuda/lib64/    #复制动态链接库
        cd /usr/local/cuda/lib64/
        sudo rm -rf libcudnn.so libcudnn.so.5    #删除原有动态文件
        sudo ln -s libcudnn.so.5.1.10 libcudnn.so.5  #生成软衔接（注意这里要和自己下载的cudnn版本对应，可以在/usr/local/cuda/lib64下查看自己libcudnn的版本）
        sudo ln -s libcudnn.so.5 libcudnn.so      #生成软链接
    fi

    echo "请到 https://opencv.org/releases.html 下载相对于版本的 opencv"
    echo "并把它放到 ~/script_install 下并改名为opencv.zip"

    sleep 5
    sudo apt-get install unzip
    cd ~/script_install
    unzip opencv.zip

    cd opencv*
    mkdir build
    cd build

    cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local ..
    if $?;then
        make -j4
        if $?;then
            sudo make install
            if $?;then
                pkg-config --modversion opencv
            fi
        fi
    fi
}



start(){
    if [ ! "$(apt list --installed 2>/dev/null | grep ros-$rosversion-desktop-full)" ];then
        install_ros
    elif [ ! "$(tree -L 2 ~ | grep devel)" ];then
        make_ros_dir
    fi
}