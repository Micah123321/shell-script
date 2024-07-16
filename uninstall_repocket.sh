#!/bin/bash

# 停止并禁用服务
sudo systemctl stop repocket
sudo systemctl disable repocket

# 删除服务文件
sudo rm /etc/systemd/system/repocket.service

# 删除环境文件
sudo rm /etc/default/repocket

# 删除可执行文件
sudo rm /usr/local/bin/repocket

# 重新加载 systemd 守护进程
sudo systemctl daemon-reload

# 可选：清理日志文件
sudo journalctl --vacuum-time=1s

echo "Repocket 服务已卸载。"
