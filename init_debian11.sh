#!/bin/bash

# 设置非交互模式，防止apt等命令在执行过程中等待用户输入
export DEBIAN_FRONTEND=noninteractive

# 全局变量
INTERACTIVE_MODE=true
DEBIAN_VERSION=""
DEBIAN_CODENAME=""
OS=""

# 检查是否传入非交互模式参数
if [ "$1" == "--non-interactive" ]; then
    INTERACTIVE_MODE=false
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

# 函数：检查是否以root权限运行
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        handle_error 1 "此脚本必须以root权限运行。"
    fi
}

# 函数：检测系统类型和版本
detect_os() {
    if [ -f /etc/debian_version ]; then
        # 检查 lsb_release 是否存在，如果不存在则安装
        if ! command -v lsb_release &>/dev/null; then
            echo "未检测到 lsb_release 工具，正在安装..."
            apt update
            apt install -y lsb-release
            handle_error $? "安装 lsb_release 失败。"
        fi

        DEBIAN_VERSION=$(lsb_release -sr)
        DEBIAN_CODENAME=$(lsb_release -sc)

        if [[ "$DEBIAN_VERSION" == "11"* ]]; then
            OS="Debian11"
        elif [[ "$DEBIAN_VERSION" == "12"* ]]; then
            OS="Debian12"
        elif [[ "$DEBIAN_VERSION" == "10"* ]]; then
            echo "检测到系统为 Debian $DEBIAN_VERSION (代号: $DEBIAN_CODENAME)。"
            echo "仅支持 Debian 11、12，自动将系统升级到 Debian 11。"
            upgrade_debian10_to_11
            detect_os # 重新检测系统信息
        else
            echo "不支持的 Debian 版本: $DEBIAN_VERSION。仅支持 Debian 11 和 12。"
            exit 1
        fi
        echo "检测到操作系统: $OS (Debian $DEBIAN_VERSION, 代号: $DEBIAN_CODENAME)"
    else
        echo "不支持的操作系统。"
        exit 1
    fi
}

# 函数：升级 Debian 10 到 Debian 11
upgrade_debian10_to_11() {
    echo "开始升级 Debian 10 到 Debian 11..."

    # 备份源列表
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    echo "已备份当前的 APT 源文件到 /etc/apt/sources.list.bak"

    # 更新源列表为 Debian 11
    cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://deb.debian.org/debian-security bullseye-security main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
EOF

    handle_error $? "更新 APT 源列表失败。"

    # 更新和升级系统
    apt update
    handle_error $? "更新包列表失败。"
    apt upgrade -y
    handle_error $? "升级系统失败。"
    apt full-upgrade -y
    handle_error $? "执行完整升级失败。"

    # 删除不需要的软件包
    apt autoremove --purge -y
    apt autoclean -y
    echo "已完成系统包的清理。"

    # 更新内核和重启系统
    echo "升级到 Debian 11 已完成，现在需要重启系统以应用更改。"
    read -p "是否立即重启系统？ [y/n] " -e reboot_choice
    reboot_choice=${reboot_choice:-y}
    if [[ $reboot_choice == "y" || $reboot_choice == "Y" ]]; then
        reboot
    else
        echo "请记得稍后手动重启系统以完成升级。"
        exit 0
    fi
}


# 函数：检测是否运行在GCP上
detect_gcp() {
    echo "检测是否运行在 Google Cloud Platform (GCP) 上..."
    # 使用超时参数防止卡住
    if timeout 3s curl -s -f -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/ > /dev/null 2>&1; then
        echo "检测到当前机器运行在 GCP 上。"
        execute_gcp_actions
    else
        echo "当前机器未运行在 GCP 上。"
    fi
}


# 函数：在GCP上执行的操作
execute_gcp_actions() {
    echo "执行GCP特定操作：下载并运行 test_delay.sh 脚本..."
    wget https://raw.githubusercontent.com/Micah123321/shell-script/main/test_delay.sh
    handle_error $? "下载 test_delay.sh 失败。"
    chmod +x test_delay.sh
    ./test_delay.sh
    handle_error $? "执行 test_delay.sh 失败。"
    echo "GCP特定操作已完成。"
}

# 函数：更新源列表
update_sources_list() {
    if [ -f /etc/apt/sources.list.d/google-cloud.list ]; then
        echo "检测到谷歌云源，删除谷歌云源..."
        rm -f /etc/apt/sources.list.d/google-cloud.list
        apt autoremove -y
    fi
    # 根据 Debian 版本设置代号
    if [[ "$OS" == "Debian11" ]]; then
        CODENAME="bullseye"
    elif [[ "$OS" == "Debian12" ]]; then
        CODENAME="bookworm"
    else
        echo "不支持的 Debian 版本: $OS"
        exit 1
    fi

    # 检查是否已包含 bullseye 或 bookworm backports
    if grep -q "deb-src http://deb.debian.org/debian $CODENAME-backports main contrib non-free" /etc/apt/sources.list; then
        echo "源列表已包含 $CODENAME-backports。跳过更新。"
        return
    fi

    if [ "$INTERACTIVE_MODE" == true ]; then
        read -p "是否要更新源列表? (y/n) " -e update_sources
        update_sources=${update_sources:-y}
    else
        update_sources="y"
    fi

    if [[ $update_sources == "y" || $update_sources == "Y" ]]; then
        echo "更新源列表..."
    else
        return
    fi

    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    echo "备份文件: /etc/apt/sources.list.bak"

    cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian/ $CODENAME main
deb-src http://deb.debian.org/debian/ $CODENAME main

deb http://security.debian.org/debian-security $CODENAME-security main
deb-src http://security.debian.org/debian-security $CODENAME-security main

deb http://deb.debian.org/debian/ $CODENAME-updates main
deb-src http://deb.debian.org/debian/ $CODENAME-updates main

deb http://deb.debian.org/debian $CODENAME-backports main contrib non-free
deb-src http://deb.debian.org/debian $CODENAME-backports main contrib non-free
EOF
    handle_error $? "更新源列表失败。"
    echo "源列表已更新为 $CODENAME。"
}

# 函数：优化DNS服务器
optimize_dns() {
    if [ "$INTERACTIVE_MODE" == true ]; then
        read -p "是否要优化DNS服务器? (y/n) " -e optimize_dns
        optimize_dns=${optimize_dns:-y}
    else
        optimize_dns="y"
    fi

    if [[ $optimize_dns == "y" || $optimize_dns == "Y" ]]; then
        echo "优化DNS服务器..."
    else
        return
    fi

    # 检查IPv6连接
    if ping6 -c 1 google.com > /dev/null 2>&1; then
        IPV6_AVAILABLE=true
    else
        IPV6_AVAILABLE=false
    fi

    # 检查IPv4连接
    if ping -c 1 google.com > /dev/null 2>&1; then
        IPV4_AVAILABLE=true
    else
        IPV4_AVAILABLE=false
    fi

    cp /etc/resolv.conf /etc/resolv.conf.bak
    echo "备份文件: /etc/resolv.conf.bak"

    if [ "$IPV6_AVAILABLE" = true ] && [ "$IPV4_AVAILABLE" = true ]; then
        cat > /etc/resolv.conf << EOF
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
nameserver 9.9.9.9
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    elif [ "$IPV4_AVAILABLE" = true ]; then
        cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 9.9.9.9
nameserver 8.8.8.8
EOF
    elif [ "$IPV6_AVAILABLE" = true ]; then
        cat > /etc/resolv.conf << EOF
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
EOF
    else
        echo "未检测到IPv4或IPv6连接。DNS未更改。"
        return
    fi

    handle_error $? "优化DNS服务器失败。"
    echo "DNS服务器已优化。"
}

# 函数：安装基础工具
install_base_tools() {
    if [[ "$OS" == "Ubuntu" ]]; then
        KEYS=("112695A0E562B32A" "54404762BBB6E853" "0E98404D386FA1D9" "6ED0E7B82643E131" "605C66F00D6C9793")

        for KEY in "${KEYS[@]}"; do
            if ! apt-key list | grep -q "$KEY"; then
                echo "添加密钥: $KEY"
                apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$KEY"
                handle_error $? "添加密钥 $KEY 失败。"
            fi
        done
    fi

    echo "更新和升级系统..."
    apt update && apt upgrade -y && apt dist-upgrade -y && apt full-upgrade -y && apt autoremove -y
    handle_error $? "系统更新和升级失败。"

    echo "安装基础工具..."
    apt install -y lsof curl git sudo wget net-tools screen iperf3 dnsutils telnet openssl btop nftables bc
    handle_error $? "安装基础工具失败。"
    echo "基础工具安装完成。"
}

# 函数：安装XrayR
install_xrayr() {
    if ! command -v xrayr &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "是否要安装 XrayR? (y/n) " -e install_xrayr
            install_xrayr=${install_xrayr:-y}
        else
            install_xrayr="y"
        fi

        if [[ $install_xrayr == "y" || $install_xrayr == "Y" ]]; then
            echo "安装 XrayR..."
            wget -N https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/micah123321/XrayR-release/master/install.sh
            handle_error $? "下载 XrayR 安装脚本失败。"
            bash install.sh v1.0
            handle_error $? "安装 XrayR 失败。"
            xrayr update
            handle_error $? "更新 XrayR 失败。"
            echo "XrayR 安装和更新完成。"
        fi
    else
        echo "XrayR 已经安装。跳过安装。"
    fi
}

# 函数：安装Fail2Ban
install_fail2ban() {
    if ! command -v fail2ban-client &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "是否要安装 Fail2Ban? (y/n) " -e install_f2b
            install_f2b=${install_f2b:-y}
        else
            install_f2b="y"
        fi

        if [[ $install_f2b == "y" || $install_f2b == "Y" ]]; then
            echo "安装 Fail2Ban..."

            if [[ "$OS" == "Debian11" || "$OS" == "Debian12" ]]; then
                apt update
                handle_error $? "更新软件包列表失败。"
                apt install -y fail2ban
                handle_error $? "安装 Fail2Ban 失败。"
                systemctl enable fail2ban
                systemctl start fail2ban
                handle_error $? "启动或启用 Fail2Ban 服务失败。"

                # 备份并配置 jail.local
                if [ -f /etc/fail2ban/jail.local ]; then
                    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
                    echo "备份原有的 jail.local 为 jail.local.bak"
                fi

                # 获取SSH端口
                SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
                SSH_PORT=${SSH_PORT:-22}

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

            elif [ "$OS" = "CentOS" ]; then
                yum install -y epel-release
                handle_error $? "安装 EPEL 仓库失败。"
                yum install -y fail2ban
                handle_error $? "安装 Fail2Ban 失败。"
                systemctl enable fail2ban
                systemctl start fail2ban
                handle_error $? "启动或启用 Fail2Ban 服务失败。"

                # 备份并配置 jail.local
                if [ -f /etc/fail2ban/jail.local ]; then
                    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
                    echo "备份原有的 jail.local 为 jail.local.bak"
                fi

                # 获取SSH端口
                SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
                SSH_PORT=${SSH_PORT:-22}

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
            fi

            echo "重新启动 Fail2Ban 服务以应用配置..."
            systemctl restart fail2ban
            handle_error $? "重新启动 Fail2Ban 服务失败。"

            echo "Fail2Ban 安装和配置完成。"
        fi
    else
        echo "Fail2Ban 已经安装。跳过安装。"
    fi
}

# 函数：安装Docker
install_docker() {
    # 检查系统内存是否大于512MB
    total_memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    if [ "$total_memory" -le 1024288 ]; then
        echo "内存不足，无法安装 Docker。需要超过1024MB的内存。"
        return
    fi

    if ! command -v docker &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "是否要安装 Docker? (y/n) " -e install_docker
            install_docker=${install_docker:-y}
        else
            install_docker="y"
        fi

        if [[ $install_docker == "y" || $install_docker == "Y" ]]; then
            echo "开始安装 Docker..."

            # 更新包列表
            apt update
            handle_error $? "更新软件包列表失败。"

            # 安装必要的包
            apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
            handle_error $? "安装必要的包失败。"

            # 添加 Docker 的官方 GPG 密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
            handle_error $? "添加 Docker GPG 密钥失败。"

            # 验证密钥指纹
            apt-key fingerprint 0EBFCD88
            handle_error $? "验证 Docker GPG 密钥失败。"

            # 添加 Docker APT 仓库
            add-apt-repository \
               "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian \
               $DEBIAN_CODENAME \
               stable"
            handle_error $? "添加 Docker 仓库失败。"

            # 更新包列表
            apt update
            handle_error $? "更新软件包列表失败。"

            # 安装 Docker Engine
            apt install -y docker-ce docker-ce-cli containerd.io
            handle_error $? "安装 Docker 失败。"

            # 启动并启用 Docker 服务
            systemctl enable docker
            systemctl start docker
            handle_error $? "启动或启用 Docker 服务失败。"

            echo "安装 Docker Compose..."
            # 下载 Docker Compose
            curl -L "https://gh-proxy.535888.xyz/https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            handle_error $? "下载 Docker Compose 失败。"
            chmod +x /usr/local/bin/docker-compose
            handle_error $? "赋予 Docker Compose 可执行权限失败。"

            echo "Docker 和 Docker Compose 安装完成。"
        fi
    else
        echo "Docker 已经安装。跳过安装。"
    fi
}

# 函数：设置时区为上海
set_timezone_shanghai() {
    echo "设置时区为上海..."
    timedatectl set-timezone Asia/Shanghai
    handle_error $? "设置时区失败。"
    echo "时区已设置为上海。"
}

# 函数：开启BBR
enable_bbr() {
    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [ "$congestion_algorithm" == "bbr" ]; then
        echo "BBR 已经启用。跳过。"
        return
    fi

    echo "启用 BBR..."
    curl -o tcpx.sh "https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh"
    handle_error $? "下载 tcpx.sh 失败。"
    chmod +x tcpx.sh
    ./tcpx.sh
    handle_error $? "启用 BBR 失败。"
    echo "BBR 已启用。"
}

# 移除其他加速模块
remove_bbr_lotserver() {
    # 清理与BBR和FQ相关的配置
    sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

    # 清理其他与内存、TCP相关的配置
    sed -i '/vm.swappiness/d' /etc/sysctl.conf
    sed -i '/vm.dirty_ratio/d' /etc/sysctl.conf
    sed -i '/vm.dirty_background_ratio/d' /etc/sysctl.conf
    sed -i '/vm.overcommit_memory/d' /etc/sysctl.conf
    sed -i '/vm.min_free_kbytes/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_pacing_ca_ratio/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_window_scaling/d' /etc/sysctl.conf
    sed -i '/vm.vfs_cache_pressure/d' /etc/sysctl.conf
    sed -i '/kernel.sched_autogroup_enabled/d' /etc/sysctl.conf
    sed -i '/kernel.numa_balancing/d' /etc/sysctl.conf

    # 重新加载sysctl配置
    sysctl --system

    # 移除BBR和lotServer的安装脚本和配置
    rm -rf tcpx.sh bbrmod

    if [[ -e /appex/bin/lotServer.sh ]]; then
        bash <(wget -qO- https://raw.githubusercontent.com/fei5seven/lotServer/master/lotServerInstall.sh) uninstall
    fi
}

# 启用BBR+FQ，并添加其他内核参数
startbbrfq() {
    remove_bbr_lotserver

    # 启用BBR和FQ
    echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf

    # 添加其他系统参数
    echo "vm.swappiness=10" >> /etc/sysctl.d/99-sysctl.conf
    echo "vm.dirty_ratio=15" >> /etc/sysctl.d/99-sysctl.conf
    echo "vm.dirty_background_ratio=5" >> /etc/sysctl.d/99-sysctl.conf
    echo "vm.overcommit_memory=1" >> /etc/sysctl.d/99-sysctl.conf
    echo "vm.min_free_kbytes=65536" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.core.rmem_max=16777216" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.core.wmem_max=16777216" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.core.netdev_max_backlog=250000" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.core.somaxconn=4096" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_rmem=4096 87380 16777216" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_wmem=4096 65536 16777216" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_max_syn_backlog=8192" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_tw_reuse=1" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.ip_local_port_range=1024 65535" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_pacing_ca_ratio=110" >> /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_window_scaling=2" >> /etc/sysctl.d/99-sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-sysctl.conf
    echo "kernel.sched_autogroup_enabled=0" >> /etc/sysctl.d/99-sysctl.conf
    echo "kernel.numa_balancing=0" >> /etc/sysctl.d/99-sysctl.conf

    # 重新加载sysctl配置
    sysctl --system

    echo "BBR+FQ和内核参数修改成功，重启生效！"
}

# 函数：清理Debian系统
clean_debian() {
    echo "清理系统..."
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=50M
    apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
    echo "系统清理完成。"
}

# 函数: 获取系统信息
get_system_info() {
    if command -v lsb_release >/dev/null 2>&1; then
        os_info=$(lsb_release -ds 2>/dev/null)
    else
        if [ -f "/etc/os-release" ]; then
            os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
        elif [ -f "/etc/debian_version" ]; then
            os_info="Debian $(cat /etc/debian_version)"
        elif [ -f "/etc/redhat-release" ]; then
            os_info=$(cat /etc/redhat-release)
        else
            os_info="Unknown"
        fi
    fi
}

# 函数: 获取CPU型号
get_cpu_model() {
    cpu_info=$(grep "model name" /proc/cpuinfo | uniq | awk -F': ' '{print $2}' | sed 's/^[ \t]*//')
    if [ -z "$cpu_info" ]; then
        cpu_info="Unknown"
    fi
}

# 函数: 获取CPU占用率
get_cpu_usage() {
    if [ -f /proc/stat ]; then
        # 获取第一行cpu数据
        cpu_info=($(grep '^cpu ' /proc/stat))
        # 计算总时间
        total_cpu_usage=0
        for (( i=1; i<${#cpu_info[@]}; i++ )); do
            total_cpu_usage=$((total_cpu_usage + ${cpu_info[$i]}))
        done
        # idle时间
        idle_cpu_usage=${cpu_info[4]}
        # 计算CPU使用率
        cpu_usage_percent=$((100 - ((100 * idle_cpu_usage) / total_cpu_usage)))
    else
        cpu_usage_percent="Unknown"
    fi
}

# 函数: 显示系统信息
display_system_info() {
    hostname=$(hostname)
    kernel_version=$(uname -r)
    cpu_arch=$(uname -m)
    cpu_cores=$(nproc)
    mem_info=$(free -m | awk 'NR==2{printf "%.2f/%.2f GB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    swap_info=$(free -m | awk 'NR==3{printf "%.2f/%.2f GB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')
    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/)
    country=$(curl -s ipinfo.io/country)
    city=$(curl -s ipinfo.io/city)
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    runtime=$(uptime -p)

    echo ""
    echo "系统信息查询"
    echo "------------------------"
    echo "主机名: $hostname"
    echo "系统版本: $os_info"
    echo "Linux版本: $kernel_version"
    echo "------------------------"
    echo "CPU架构: $cpu_arch"
    echo "CPU型号: $cpu_info"
    echo "CPU核心数: $cpu_cores"
    echo "------------------------"
    echo "CPU占用: $cpu_usage_percent%"
    echo "物理内存: $mem_info"
    echo "虚拟内存: $swap_info"
    echo "硬盘占用: $disk_info"
    echo "------------------------"
    echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
    echo "------------------------"
    echo "公网IPv4地址: $ipv4_address"
    echo "公网IPv6地址: $ipv6_address"
    echo "------------------------"
    echo "地理位置: $country $city"
    echo "系统时间: $current_time"
    echo "------------------------"
    echo "系统运行时长: $runtime"
    echo ""
}

# 函数：开启WARP流媒体分流
enable_warp_streaming() {
    if command -v warp &> /dev/null; then
        echo "WARP服务已安装。跳过下载和执行。"
        return
    fi

    if [ "$INTERACTIVE_MODE" == true ]; then
        read -p "是否要启用 WARP 流媒体分流? (y/n) " -e warp_choice
        warp_choice=${warp_choice:-y}
    else
        warp_choice="y"
    fi

    if [[ $warp_choice == "y" || $warp_choice == "Y" ]]; then
        echo "启用WARP流媒体分流..."
        wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
        handle_error $? "下载 WARP 安装脚本失败。"
        chmod +x menu.sh
        ./menu.sh e
        handle_error $? "启用 WARP 流媒体分流失败。"
        echo "WARP 流媒体分流已启用。"
    else
        echo "跳过 WARP 流媒体分流设置。"
    fi
}

# 添加检查内存和设置swap的函数
check_and_setup_swap() {
    echo "检查内存状态..."

    # 获取总内存(KB)并转换为GB
    total_mem_gb=$(awk '/MemTotal/ {printf "%.2f", $2/1024/1024}' /proc/meminfo)
    echo "当前系统内存: ${total_mem_gb}GB"

    # 检查是否已开启swap
    swap_enabled=$(swapon --show | wc -l)

    if [ "$swap_enabled" -gt 0 ]; then
        # 如果已开启swap，显示当前swap信息
        swap_info=$(free -h | awk '/Swap:/ {print $2}')
        echo "检测到已开启swap，当前大小: ${swap_info}"
        return
    else
        echo "当前未开启swap"
    fi

    # 获取可用磁盘空间(GB)
    free_disk_gb=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')
    echo "可用磁盘空间: ${free_disk_gb}GB"

    # 如果内存小于1.1GB，没有swap，且剩余空间大于5GB
    if (( $(echo "$total_mem_gb < 1.1" | bc -l) )) && [ "$swap_enabled" -eq 0 ] && [ "$free_disk_gb" -gt 5 ]; then
        echo "检测到内存不足1.1GB，且未开启swap，将自动设置1GB的swap空间..."

        # 下载setup_swap.sh脚本
        curl -L -s -o setup_swap.sh https://ghproxy.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/setup_swap.sh
        chmod +x setup_swap.sh

        # 自动输入1GB并执行脚本
        echo "1" | ./setup_swap.sh

        # 清理脚本文件
        rm -f setup_swap.sh
    else
        if (( $(echo "$total_mem_gb >= 1.1" | bc -l) )); then
            echo "系统内存充足，无需设置swap"
        elif [ "$free_disk_gb" -le 5 ]; then
            echo "可用磁盘空间不足5GB，无法设置swap"
        fi
    fi
}

# 主执行逻辑
main() {
    check_root
    detect_os
    detect_gcp  # 添加的GCP检测函数调用
    update_sources_list
    optimize_dns
    install_base_tools
    check_and_setup_swap
    # enable_bbr
    startbbrfq  # 调用启用 BBR+FQ 加速的函数
    install_xrayr
    install_fail2ban
    install_docker
    set_timezone_shanghai
    # enable_warp_streaming
    clean_debian
    get_system_info
    get_cpu_model
    get_cpu_usage
    display_system_info
    echo "初始化和优化完成。"
}

# 执行主函数并记录日志
main | tee /var/log/setup_script.log
