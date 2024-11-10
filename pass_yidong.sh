#!/bin/bash

# 一键安装 Geneva TCP Window Modifier 脚本
# 兼容 Debian 11 和 Debian 12

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

# 检查是否以 root 权限运行
if [[ "$EUID" -ne 0 ]]; then
    echo_error "请以 root 用户运行此脚本。使用 sudo ./install_geneva.sh"
fi

# 检测 Debian 版本
if command -v lsb_release >/dev/null 2>&1; then
    DEBIAN_VERSION=$(lsb_release -sr | cut -d '.' -f1,2)
else
    # 备选方法
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DEBIAN_VERSION=$VERSION_ID
    else
        echo_error "无法检测 Debian 版本。请确保系统是 Debian 11 或 Debian 12。"
    fi
fi

if [[ "$DEBIAN_VERSION" != "11" && "$DEBIAN_VERSION" != "12" ]]; then
    echo_error "此脚本仅支持 Debian 11 和 Debian 12。当前版本：$DEBIAN_VERSION"
fi

echo_info "检测到 Debian $DEBIAN_VERSION"

# 检测当前机器是否是谷歌云的，如果 /etc/apt/sources.list.d/google-cloud.list 有文件则删除
if [ -f /etc/apt/sources.list.d/google-cloud.list ]; then
    echo_info "检测到谷歌云源，删除谷歌云源..."
    rm -f /etc/apt/sources.list.d/google-cloud.list
    apt-get autoremove -y
fi

# 更新系统包列表并升级
echo_info "更新系统包列表并升级现有包..."
apt-get update -y && apt-get upgrade -y

# 安装必要的系统依赖
echo_info "安装必要的系统依赖..."
apt-get install -y build-essential python3 python3-dev python3-pip libnetfilter-queue-dev libffi-dev libssl-dev iptables git python3-venv netfilter-persistent

sudo pip3 install --upgrade pip
sudo pip3 install scapy netfilterqueue

# 保存 geneva.py 脚本
echo_info "保存 geneva.py 脚本到 root..."
cat << 'EOF' > geneva.py
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
chmod +x geneva.py

# 配置 iptables 规则
echo_info "配置 iptables 规则..."
# 清除旧的规则以避免重复
iptables -D OUTPUT -p tcp --sport 80 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 100 2>/dev/null || true
iptables -D OUTPUT -p tcp --sport 443 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 101 2>/dev/null || true

# 添加新的规则
iptables -I OUTPUT -p tcp --sport 80 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 100
iptables -I OUTPUT -p tcp --sport 443 --tcp-flags SYN,RST,ACK,FIN,PSH SYN,ACK -j NFQUEUE --queue-num 101

# 保存 iptables 规则
echo_info "保存 iptables 规则..."
netfilter-persistent save

# 创建 Systemd 服务文件
SERVICE_FILE_100="/etc/systemd/system/geneva-100.service"
SERVICE_FILE_101="/etc/systemd/system/geneva-101.service"

echo_info "创建 Systemd 服务文件 $SERVICE_FILE_100..."
cat <<'EOF' > "$SERVICE_FILE_100"
[Unit]
Description=Geneva TCP Window Modifier - Queue 100
After=network.target

[Service]
Type=simple
ExecStart=python3 /root/geneva.py -q 100 -w 17
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

echo_info "创建 Systemd 服务文件 $SERVICE_FILE_101..."
cat <<'EOF' > "$SERVICE_FILE_101"
[Unit]
Description=Geneva TCP Window Modifier - Queue 101
After=network.target

[Service]
Type=simple
ExecStart=python3 /root/geneva.py -q 101 -w 4
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

# 启动并启用 geneva-101.service
echo_info "启动 geneva-101.service 服务..."
systemctl start geneva-101.service
systemctl enable geneva-101.service

# 检查服务状态
echo_info "检查 geneva-100.service 服务状态..."
systemctl status geneva-100.service --no-pager

echo_info "检查 geneva-101.service 服务状态..."
systemctl status geneva-101.service --no-pager

# 完成
echo_info "Geneva TCP Window Modifier 安装和配置完成！"

# 提示用户如何查看日志
echo_info "您可以使用以下命令查看服务日志："
echo -e "\e[34mjournalctl -u geneva-100.service -f\e[0m"
echo -e "\e[34mjournalctl -u geneva-101.service -f\e[0m"
