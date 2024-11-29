#!/bin/bash

# 一键安装 Geneva TCP Window Modifier 脚本
# 兼容 Debian 11、Debian 12 和 CentOS 7

set -e

# 函数：打印信息
echo_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

# 函数：打印错误信息并退出
echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
    exit 1
}
# 在脚本开头添加检测函数
check_is_china() {
    echo_info "正在检测服务器环境..."
    # 尝试访问 Google,超时时间设置为 3 秒
    if curl -m 3 -s www.google.com -o /dev/null; then
        echo_info "可以访问 Google,使用官方软件源..."
        return 1  # 可以访问 Google,不是中国机器
    else
        echo_info "无法访问 Google,判断为中国环境,将使用国内软件源..."
        return 0  # 不能访问 Google,是中国机器
    fi
}

# 检查是否以 root 权限运行
if [[ "$EUID" -ne 0 ]]; then
    echo_error "请以 root 用户运行此脚本。使用 sudo ./install_geneva.sh"
fi

# 检测操作系统和版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID_NUM=$(echo "$VERSION_ID" | cut -d '.' -f1)
else
    echo_error "无法检测操作系统。请确保是 Debian、Ubuntu 或 CentOS 系统。"
fi

# 根据操作系统设置变量
if [[ "$OS" == "debian" ]]; then
    PACKAGE_MANAGER="apt"
    UPDATE_CMD="apt-get update -y"
    UPGRADE_CMD="apt-get upgrade -y"
    INSTALL_CMD="apt-get install -y"
    DEBIAN_VERSION=$VERSION_ID_NUM
    # 仅支持 Debian 11 和 Debian 12
    if [[ "$DEBIAN_VERSION" != "11" && "$DEBIAN_VERSION" != "12" ]]; then
        echo_error "此脚本仅支持 Debian 11 和 Debian 12。当前版本：$DEBIAN_VERSION"
    fi
    echo_info "检测到 Debian $DEBIAN_VERSION"

elif [[ "$OS" == "ubuntu" ]]; then
    PACKAGE_MANAGER="apt"
    UPDATE_CMD="apt-get update -y"
    UPGRADE_CMD="apt-get upgrade -y"
    INSTALL_CMD="apt-get install -y"
    UBUNTU_VERSION=$VERSION_ID_NUM
    # 仅支持 Ubuntu 22.04
    if [[ "$VERSION_ID" != "22.04" ]]; then
        echo_error "此脚本仅支持 Ubuntu 22.04。当前版本：$VERSION_ID"
    fi
    echo_info "检测到 Ubuntu $VERSION_ID"

elif [[ "$OS" == "centos" ]]; then
    PACKAGE_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    UPGRADE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
    CENTOS_VERSION=$VERSION_ID_NUM
    # 仅支持 CentOS 7
    if [[ "$CENTOS_VERSION" != "7" ]]; then
        echo_error "此脚本仅支持 CentOS 7。当前版本：$CENTOS_VERSION"
    fi
    echo_info "检测到 CentOS $CENTOS_VERSION"
else
    echo_error "不支持的操作系统：$OS。仅支持 Debian 11、Debian 12、Ubuntu 22.04 和 CentOS 7。"
fi

# 针对 Ubuntu/Debian 的包安装部分
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    # 检查是否已安装 python3
    if command -v python3 >/dev/null 2>&1; then
        echo_info "检测到 python3 已安装，安装 python3-dev 及其他相关包。"
        PACKAGES="build-essential libnetfilter-queue-dev libffi-dev libssl-dev iptables git netfilter-persistent python3-venv python3-dev"
    else
        echo_info "未检测到 python3，安装 python3 及相关包。"
        PACKAGES="build-essential python3 python3-dev python3-pip python3-venv libnetfilter-queue-dev libffi-dev libssl-dev iptables git netfilter-persistent"
    fi

    # 针对 Ubuntu/Debian，检测是否为谷歌云并删除源
    if [ -f /etc/apt/sources.list.d/google-cloud.list ]; then
        echo_info "检测到谷歌云源，删除谷歌云源..."
        rm -f /etc/apt/sources.list.d/google-cloud.list
        $PACKAGE_MANAGER autoremove -y
    fi
fi

# 针对 CentOS 安装 EPEL 仓库
if [[ "$OS" == "centos" ]]; then
    if ! yum repolist | grep -q "^epel/"; then
        echo_info "安装 EPEL 仓库..."
        yum install -y epel-release
    fi
fi

# 针对 Debian，检测是否为谷歌云并删除源
if [[ "$OS" == "debian" ]]; then
    if [ -f /etc/apt/sources.list.d/google-cloud.list ]; then
        echo_info "检测到谷歌云源，删除谷歌云源..."
        rm -f /etc/apt/sources.list.d/google-cloud.list
        $PACKAGE_MANAGER autoremove -y
    fi
fi

# 更新系统包列表并升级
echo_info "更新系统包列表并升级现有包..."
$UPDATE_CMD && $UPGRADE_CMD

# 根据操作系统设置安装包列表
if [[ "$OS" == "debian" ]]; then
    # 检查是否已安装 python3
    if command -v python3 >/dev/null 2>&1; then
        echo_info "检测到 python3 已安装，安装 python3-dev 及其他相关包。"
        PACKAGES="build-essential libnetfilter-queue-dev libffi-dev libssl-dev iptables git netfilter-persistent python3-venv python3-dev"
    else
        echo_info "未检测到 python3，安装 python3 及相关包。"
        PACKAGES="build-essential python3 python3-dev python3-pip python3-venv libnetfilter-queue-dev libffi-dev libssl-dev iptables git netfilter-persistent"
    fi
elif [[ "$OS" == "centos" ]]; then
    # CentOS 7 使用不同的软件包名称
    echo_info "检测 CentOS 7 环境，安装必要的依赖包。"
    PACKAGES="gcc gcc-c++ make libnetfilter_queue-devel libffi-devel openssl-devel iptables git python3 python3-pip python3-virtualenv iptables-services"
fi

# 安装必要的系统依赖
echo_info "安装必要的系统依赖..."
$INSTALL_CMD $PACKAGES
$INSTALL_CMD python3-dev

# 创建虚拟环境
VENV_DIR="/opt/geneva_venv"
if [ -d "$VENV_DIR" ]; then
    echo_info "虚拟环境已存在，跳过创建虚拟环境。"
else
    echo_info "创建 Python 虚拟环境..."
    python3 -m venv "$VENV_DIR"
fi

# 激活虚拟环境并安装 Python 包
echo_info "激活虚拟环境并安装必要的 Python 包..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# 检查是否为中国机器并相应配置pip源
if check_is_china; then
    echo_info "配置使用清华镜像源..."
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
    PIP_SOURCE="-i https://pypi.tuna.tsinghua.edu.cn/simple"
else
    echo_info "使用官方软件源..."
    PIP_SOURCE=""
fi

# 升级pip并安装必要包
echo_info "升级pip并安装必要包..."
python3 -m pip install --upgrade pip $PIP_SOURCE
python3 -m pip install scapy netfilterqueue $PIP_SOURCE
deactivate

# 保存 geneva.py 脚本
echo_info "保存 geneva.py 脚本到 /opt/geneva/..."
mkdir -p /opt/geneva
cat << 'EOF' > /opt/geneva/geneva.py
#!/usr/bin/env python3

import os
import signal
import sys
import logging
from scapy.all import IP, TCP
from netfilterqueue import NetfilterQueue
import argparse

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

def modify_window(pkt, window_size, target_flags):
    """
    修改TCP窗口大小。

    :param pkt: NetfilterQueue中的数据包
    :param window_size: 目标窗口大小
    :param target_flags: 需要修改窗口大小的TCP标志集合
    """
    try:
        ip_packet = IP(pkt.get_payload())
        if ip_packet.haslayer(TCP):
            tcp_layer = ip_packet[TCP]
            # 使用 pkt.sprintf 获取 TCP flags 的字符串表示
            flags_str = ip_packet.sprintf("%TCP.flags%")
            if flags_str in target_flags:
                logging.debug(f"Modifying window size for packet with flags: {flags_str}")
                tcp_layer.window = window_size
                # 删除校验和，确保Scapy重新计算
                del ip_packet.chksum
                del tcp_layer.chksum
                pkt.set_payload(bytes(ip_packet))
                # logging.info(f"Set window size to {window_size} for flags {flags_str}")
    except Exception as e:
        logging.error(f"Error modifying packet: {e}")
    finally:
        pkt.accept()

def parse_arguments():
    """
    解析命令行参数。

    :return: 队列号和窗口大小
    """
    parser = argparse.ArgumentParser(
        description='修改指定TCP标志的数据包窗口大小'
    )

    parser.add_argument(
        '-q', '--queue',
        type=int,
        required=True,
        help='iptables 队列号'
    )
    parser.add_argument(
        '-w', '--window_size',
        type=int,
        required=True,
        help='TCP 窗口大小'
    )

    args = parser.parse_args()

    if args.window_size <= 0:
        parser.error("window_size 必须是正整数")

    return args.queue, args.window_size

def main():
    queue_num, window_size = parse_arguments()
    target_flags = {"SA", "FA", "PA", "A"}

    nfqueue = NetfilterQueue()
    try:
        nfqueue.bind(queue_num, lambda pkt: modify_window(pkt, window_size, target_flags))
        logging.info(f"NetfilterQueue绑定到队列号 {queue_num}，窗口大小设置为 {window_size}")
        logging.info("启动netfilter_queue进程...")
        nfqueue.run()
    except KeyboardInterrupt:
        logging.info("接收到中断信号，正在退出...")
    except Exception as e:
        logging.error(f"运行时错误: {e}")
    finally:
        nfqueue.unbind()
        logging.info("NetfilterQueue已解绑")

if __name__ == "__main__":
    # 确保在接收到SIGINT信号时能够优雅退出
    signal.signal(signal.SIGINT, lambda signal, frame: sys.exit(0))
    main()
EOF

# 赋予 geneva.py 执行权限
echo_info "赋予 geneva.py 执行权限..."
chmod +x /opt/geneva/geneva.py

# 配置 iptables 规则
echo_info "配置 iptables 规则..."
# 清除旧的规则以避免重复
iptables -D OUTPUT -p tcp --sport 80 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 100 2>/dev/null || true
iptables -D OUTPUT -p tcp --sport 443 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 101 2>/dev/null || true

# 添加新的规则
iptables -I OUTPUT -p tcp --sport 80 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 100
iptables -I OUTPUT -p tcp --sport 443 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 101

# 新增：配置 SYN-ACK 数据包的 iptables 规则，队列号 102
echo_info "配置 SYN-ACK 数据包的 iptables 规则..."
iptables -D OUTPUT -p tcp --sport 80 --tcp-flags SYN,ACK SYN,ACK -j NFQUEUE --queue-num 102 2>/dev/null || true
iptables -D OUTPUT -p tcp --sport 443 --tcp-flags SYN,ACK SYN,ACK -j NFQUEUE --queue-num 102 2>/dev/null || true

iptables -I OUTPUT -p tcp --sport 80 --tcp-flags SYN,ACK SYN,ACK -j NFQUEUE --queue-num 102
iptables -I OUTPUT -p tcp --sport 443 --tcp-flags SYN,ACK SYN,ACK -j NFQUEUE --queue-num 102

# 保存 iptables 规则
echo_info "保存 iptables 规则..."
if [[ "$OS" == "debian" ]]; then
    netfilter-persistent save
elif [[ "$OS" == "centos" ]]; then
    service iptables save
    systemctl enable iptables
    systemctl restart iptables
fi

# 创建 Systemd 服务文件
SERVICE_DIR="/etc/systemd/system"
SERVICE_FILE_100="$SERVICE_DIR/geneva-100.service"
SERVICE_FILE_101="$SERVICE_DIR/geneva-101.service"
SERVICE_FILE_102="$SERVICE_DIR/geneva-102.service"  # 新增服务文件

echo_info "创建 Systemd 服务文件 $SERVICE_FILE_100..."
cat <<EOF > "$SERVICE_FILE_100"
[Unit]
Description=Geneva TCP Window Modifier - Queue 100
After=network.target

[Service]
Type=simple
ExecStart=$VENV_DIR/bin/python /opt/geneva/geneva.py -q 100 -w 17
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

echo_info "创建 Systemd 服务文件 $SERVICE_FILE_101..."
cat <<EOF > "$SERVICE_FILE_101"
[Unit]
Description=Geneva TCP Window Modifier - Queue 101
After=network.target

[Service]
Type=simple
ExecStart=$VENV_DIR/bin/python /opt/geneva/geneva.py -q 101 -w 4
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# 新增：创建 Systemd 服务文件 geneva-102.service
echo_info "创建 Systemd 服务文件 $SERVICE_FILE_102..."
cat <<EOF > "$SERVICE_FILE_102"
[Unit]
Description=Geneva TCP Window Modifier - Queue 102 (SYN-ACK)
After=network.target

[Service]
Type=simple
ExecStart=$VENV_DIR/bin/python /opt/geneva/geneva.py -q 102 -w 25
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 Systemd 守护进程
echo_info "重新加载 Systemd 守护进程..."
systemctl daemon-reload

# 启动并启用 geneva-100.service
echo_info "启动 geneva-100.service 服务..."
systemctl start geneva-100.service
systemctl enable geneva-100.service
#
## 启动并启用 geneva-101.service
echo_info "启动 geneva-101.service 服务..."
systemctl start geneva-101.service
systemctl enable geneva-101.service

# 启动并启用 geneva-102.service (新增)
echo_info "启动 geneva-102.service 服务..."
systemctl start geneva-102.service
systemctl enable geneva-102.service

# 检查服务状态
echo_info "检查 geneva-100.service 服务状态..."
systemctl status geneva-100.service --no-pager
#
echo_info "检查 geneva-101.service 服务状态..."
systemctl status geneva-101.service --no-pager

echo_info "检查 geneva-102.service 服务状态..."
systemctl status geneva-102.service --no-pager

# 完成
echo_info "Geneva TCP Window Modifier 安装和配置完成！"

# 提示用户如何查看日志
echo_info "您可以使用以下命令查看服务日志："
echo -e "\e[34mjournalctl -u geneva-100.service -f\e[0m"
echo -e "\e[34mjournalctl -u geneva-101.service -f\e[0m"
echo -e "\e[34mjournalctl -u geneva-102.service -f\e[0m"  # 新增提示
