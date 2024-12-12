#!/bin/bash

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 检查系统版本
if ! grep -E "Debian GNU/Linux (11|12)" /etc/issue > /dev/null; then
    echo "此脚本仅支持Debian 11和12"
    exit 1
fi

# 获取用户输入的swap大小
read -p "请输入需要设置的swap大小(GB): " swap_size

# 验证输入是否为正整数
if ! [[ "$swap_size" =~ ^[1-9][0-9]*$ ]]; then
    echo "请输入有效的正整数!"
    exit 1
fi

# 转换GB到MB
swap_size_mb=$((swap_size * 1024))

# 检查是否已存在swap
if swapon --show | grep -q "/swapfile"; then
    echo "检测到已存在swap，将调整大小到 ${swap_size}GB"
    # 关闭并删除现有swap
    swapoff -a
    rm -f /swapfile
else
    echo "将创建 ${swap_size}GB 的swap"
fi

# 创建swap文件
echo "正在创建swap文件..."
dd if=/dev/zero of=/swapfile bs=1M count=$swap_size_mb status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 确保/etc/fstab中只有一个swap条目
sed -i '/swap/d' /etc/fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 设置vm.swappiness
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo 'vm.swappiness=50' >> /etc/sysctl.conf
else
    sed -i 's/vm.swappiness=.*/vm.swappiness=50/' /etc/sysctl.conf
fi

# 应用sysctl设置
sysctl -p > /dev/null 2>&1

# 显示结果
echo -e "\nSwap设置完成!"
echo "当前内存和Swap使用情况:"
free -h 