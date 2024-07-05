#!/bin/bash
# 脚本保存路径
SCRIPT_PATH="$HOME/Titan.sh"

RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="34m"
SKYBLUE="36m"
FUCHSIA="35m"

colorEcho() {
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

# 函数定义
start_node() {

    if [ "$1" = "first-time" ]; then
        echo "首次启动节点..."
        # 下载并解压 titan-node 到 /usr/local/bin
        sudo apt update 
        sudo apt install screen -y
        echo "正在下载并解压 titan-node..."
        wget -c https://github.com/Titannet-dao/titan-node/releases/download/v0.1.19/titan-l2edge_v0.1.19_patch_linux_amd64.tar.gz -O - | sudo tar -xz -C /usr/local/bin --strip-components=1
        mv /usr/local/bin/libgoworkerd.so /root
        export LD_LIBRARY_PATH=$LD_LIZBRARY_PATH:./libgoworkerd.so
titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
    else
        echo "启动节点监控并后台运行，请使用查看日志(screen -r titan)，或者Titan面板功能..."
        screen -dmS titan bash -c 'export LD_LIBRARY_PATH=$LD_LIZBRARY_PATH:./libgoworkerd.so
titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0'
    fi
}
bind_node() {
    echo "绑定节点...进入网页:https://test1.titannet.io/newoverview/activationcodemanagement  注册账户，并点击节点管理，点击获取身份码，在下方输入即可"
    read -p "请输入身份码: " identity_code
    echo "绑定节点，身份码为: $identity_code ..."
    export LD_LIBRARY_PATH=$LD_LIZBRARY_PATH:./libgoworkerd.so
titan-edge bind --hash=$identity_code https://api-test1.container1.titannet.io/api/v2/device/binding
}
stop_node() {
    echo "停止节点..."
    export LD_LIBRARY_PATH=$LD_LIZBRARY_PATH:./libgoworkerd.so
    titan-edge daemon stop
}
check_logs() {
    echo "查看日志..."
    screen -r titan
}

change_limit() {
    # 关闭 selinux
    echo "System initialization"
    if [ -f "/etc/selinux/config" ]; then
        sed -i 's/\(SELINUX=\).*/\1disabled/g' /etc/selinux/config
        setenforce 0 >/dev/null 2>&1
    fi

    echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    echo "net.core.netdev_max_backlog = 50000" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_max_syn_backlog = 8192" >>/etc/sysctl.conf
    echo "net.core.somaxconn = 50000" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_tw_reuse = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_tw_recycle = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_time = 1800" >>/etc/sysctl.conf
    sysctl -p >/dev/null 2>&1

    # 关闭 firewalld, ufw
    systemctl stop firewalld >/dev/null 2>&1
    systemctl disable firewalld >/dev/null 2>&1
    systemctl stop ufw >/dev/null 2>&1
    systemctl disable ufw >/dev/null 2>&1
    colorEcho $GREEN "selinux,sysctl.conf,firewall 设置完成 ."

    colorEcho $BLUE "修改系统最大连接数"
    ulimit -n 65535
    changeLimit="n"

    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 65535" >>/etc/security/limits.conf
        echo "* soft nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 65535" >>/etc/security/limits.conf
        echo "* hard nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/user.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/system.conf
        changeLimit="y"
    fi

    if [[ "$changeLimit" = "y" ]]; then
        echo "连接数限制已修改为65535,重启服务器后生效"
    else
        echo -n "当前连接数限制："
        ulimit -n
    fi
    colorEcho $GREEN "已修改最大连接数限制！"
}
# 主菜单
function main_menu() {
    clear
    echo "首次安装节点后，等待生成文件（大约1-2分钟），敲击键盘ctrl c 停止节点，再运行启动节点之后绑定身份码即可"
    echo "请选择要执行的操作:"
    echo "1) 安装节点"
    echo "2) 启动节点"
    echo "3) 绑定节点"
    echo "4) 停止节点"
    echo "5) 查看日志"
    echo "6) 系统优化"
    read -p "输入选择 (1-6): " choice
    case $choice in
        1)
            start_node first-time
            ;;
        2)
            start_node
            ;;
        3)
            bind_node
            ;;
        4)
            stop_node
            ;;
        5)
            check_logs
            ;;            
        6)
            change_limit
            ;;            
        *)
            echo "无效输入，请重新输入."
            ;;
    esac
}
# 显示主菜单
main_menu