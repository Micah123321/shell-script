#!/bin/bash

# 检测系统类型
if [ -f /etc/debian_version ] || grep -qi ubuntu /etc/os-release; then
    OS="Debian"
elif [ -f /etc/redhat-release ]; then
    OS="CentOS"
else
    echo "不支持的操作系统。"
    exit 1
fi

# 获取当前SSH连接的端口
SSH_PORT=$(ss -tnlp | grep sshd | grep -Po ':\K\d+' | head -1)

# Debian系列和Ubuntu的安装和配置
if [ "$OS" = "Debian" ]; then
    apt-get update
    apt-get install -y fail2ban
    systemctl start fail2ban
    systemctl enable fail2ban
    sudo cp /etc/fail2ban/jail.{conf,local}
    sudo bash -c "echo \"[DEFAULT]
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
bantime  = 1d
findtime  = 5m
maxretry = 3\" > /etc/fail2ban/jail.local"
    systemctl restart fail2ban
    systemctl status fail2ban

# CentOS系列的安装和配置
elif [ "$OS" = "CentOS" ]; then
    yum install -y fail2ban
    systemctl start fail2ban
    systemctl enable fail2ban
    sudo cp /etc/fail2ban/jail.{conf,local}
    sudo bash -c "echo \"[DEFAULT]
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/secure
bantime  = 1d
findtime  = 5m
maxretry = 3\" > /etc/fail2ban/jail.local"
    systemctl restart fail2ban
#    systemctl status fail2ban
fi
