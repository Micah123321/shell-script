#!/bin/bash

# 下载 Repocket 可执行文件
wget https://repocket-production.s3.fr-par.scw.cloud/repocket-executable/repocket-linux-amd64

# 移动可执行文件到 /usr/local/bin 并赋予执行权限
sudo mv repocket-linux-amd64 /usr/local/bin/repocket
sudo chmod +x /usr/local/bin/repocket

# 创建环境文件
echo "请输入您的电子邮件："
read RP_EMAIL
echo "请输入您的 API 密钥："
read RP_API_KEY

sudo bash -c "cat > /etc/default/repocket <<EOL
RP_EMAIL=$RP_EMAIL
RP_API_KEY=$RP_API_KEY
EOL"

# 创建服务文件
sudo bash -c "cat > /etc/systemd/system/repocket.service <<EOL
[Unit]
Description=Repocket

[Service]
User=root
Group=root
EnvironmentFile=/etc/default/repocket
ExecStart=/usr/local/bin/repocket

[Install]
WantedBy=multi-user.target
EOL"

# 启动服务
sudo systemctl start repocket

# 启用服务在启动时启动
sudo systemctl enable repocket

echo "Repocket 服务已安装并启动。"
