#!/bin/bash

# 更新 /etc/apt/sources.list 文件
cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian buster main contrib non-free

deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free

deb http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free
EOF

# 更新软件包列表
apt update -y

# 升级所有已安装的软件包
apt upgrade -y

# 安全升级
apt dist-upgrade -y

# 执行 init_debian11 脚本
bash <(wget -qO- https://ghp.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/init_debian11.sh)

# 脚本结束
