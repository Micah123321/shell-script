#!/bin/bash

# 设置非交互模式，防止apt等命令在执行过程中等待用户输入
export DEBIAN_FRONTEND=noninteractive

# 检测是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本。"
    exit 1
fi

# 检测系统类型
if [ -f /etc/debian_version ] || grep -qi ubuntu /etc/os-release; then
    OS="Debian"
elif [ -f /etc/redhat-release ]; then
    OS="CentOS"
else
    echo "不支持的操作系统。"
    exit 1
fi

echo "检测到的操作系统: $OS"

# 检查是否安装了ss命令
if ! command -v ss &> /dev/null; then
    echo "ss命令未找到，正在安装iproute2包..."
    if [ "$OS" = "Debian" ]; then
        apt-get update
        apt-get install -y iproute2
    elif [ "$OS" = "CentOS" ]; then
        yum install -y iproute
    fi
    handle_error $? "安装iproute2失败。"
fi

# 获取当前SSH连接的端口，默认22
SSH_PORT=$(ss -tnlp | grep sshd | grep -Po ':\K\d+' | head -1)
if [ -z "$SSH_PORT" ]; then
    SSH_PORT=22
    echo "未检测到自定义SSH端口，使用默认端口22。"
else
    echo "检测到的SSH端口: $SSH_PORT"
fi

# 函数：错误处理
handle_error() {
    local exit_code=$1
    local message=$2
    if [ "$exit_code" -ne 0 ]; then
        echo "错误: $message"
        exit "$exit_code"
    fi
}

# Debian系列和Ubuntu的安装和配置
if [ "$OS" = "Debian" ]; then
    echo "更新软件包列表..."
    apt-get update
    handle_error $? "更新软件包列表失败。"

    echo "安装 Fail2Ban..."
    apt-get install -y fail2ban
    handle_error $? "安装 Fail2Ban 失败。"

    echo "启动并启用 Fail2Ban 服务..."
    systemctl start fail2ban
    systemctl enable fail2ban
    handle_error $? "启动或启用 Fail2Ban 服务失败。"

    # 备份现有的jail.local文件
    if [ -f /etc/fail2ban/jail.local ]; then
        cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
        echo "备份原有的jail.local为jail.local.bak"
    fi

    echo "配置 Fail2Ban..."
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 1d
findtime  = 5m
maxretry = 3
backend = auto

[sshd]
enabled = true
port    = $SSH_PORT
filter  = sshd
logpath = /var/log/auth.log
EOF

    echo "重新启动 Fail2Ban 服务以应用配置..."
    systemctl restart fail2ban
    handle_error $? "重新启动 Fail2Ban 服务失败。"

    echo "Fail2Ban 安装和配置完成。"

# CentOS系列的安装和配置
elif [ "$OS" = "CentOS" ]; then
    echo "更新软件包列表..."
    yum makecache fast
    handle_error $? "更新软件包列表失败。"

    echo "安装 Fail2Ban..."
    yum install -y epel-release
    handle_error $? "安装 EPEL 仓库失败。"
    yum install -y fail2ban
    handle_error $? "安装 Fail2Ban 失败。"

    echo "启动并启用 Fail2Ban 服务..."
    systemctl start fail2ban
    systemctl enable fail2ban
    handle_error $? "启动或启用 Fail2Ban 服务失败。"

    # 备份现有的jail.local文件
    if [ -f /etc/fail2ban/jail.local ]; then
        cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
        echo "备份原有的jail.local为jail.local.bak"
    fi

    echo "配置 Fail2Ban..."
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 1d
findtime  = 5m
maxretry = 3
backend = auto

[sshd]
enabled = true
port    = $SSH_PORT
filter  = sshd
logpath = /var/log/secure
EOF

    echo "重新启动 Fail2Ban 服务以应用配置..."
    systemctl restart fail2ban
    handle_error $? "重新启动 Fail2Ban 服务失败。"

    echo "Fail2Ban 安装和配置完成。"
fi

# 显示 Fail2Ban 状态
echo "Fail2Ban 服务状态:"
systemctl status fail2ban --no-pager

echo "脚本执行完毕。"
