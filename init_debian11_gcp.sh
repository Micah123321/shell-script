#!/bin/bash

# 全局变量
INTERACTIVE_MODE=true

# 检查是否传入非交互模式参数
if [ "$1" == "--non-interactive" ]; then
    INTERACTIVE_MODE=false
fi

# 函数：错误处理
handle_error() {
    local exit_code=$1
    local message=$2
    if [ "$exit_code" -ne 0 ]; then
        echo "Error: $message"
        exit "$exit_code"
    fi
}

# 函数：检查是否以root权限运行
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        handle_error 1 "This script must be run as root."
    fi
}

# 函数：更新源列表
update_sources_list() {
      # 判断如果/etc/apt/sources.list已经包含deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free则不更新
    if grep -q "deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free" /etc/apt/sources.list; then
        echo "Sources list is already updated. Skipping update."
        return
    fi

    # 选择是否需要更新源列表
    if [ "$INTERACTIVE_MODE" == true ]; then
        read -p "Do you want to update sources list? (y/n) " -i y -e update_sources
        update_sources=${update_sources:-y}
    else
        update_sources="y"
    fi


    if [[ $update_sources == "y" || $update_sources == "Y" ]]; then
        # 输出提示信息
        echo "Updating sources list..."
    else
        return
    fi

    # 改之前先备份一份
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    # 输出备份文件路径
    echo "Backup file: /etc/apt/sources.list.bak"
    cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main

deb http://security.debian.org/debian-security bullseye-security main
deb-src http://security.debian.org/debian-security bullseye-security main

deb http://deb.debian.org/debian/ bullseye-updates main
deb-src http://deb.debian.org/debian/ bullseye-updates main

deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free
EOF
}

# 函数：优化DNS服务器
optimize_dns() {
  # 选择是否需要优化DNS服务器
  if [ "$INTERACTIVE_MODE" == true ]; then
      read -p "Do you want to optimize DNS servers? (y/n) " -i y -e optimize_dns
      optimize_dns=${optimize_dns:-y}
  else
      optimize_dns="y"
  fi


      if [[ $optimize_dns == "y" || $optimize_dns == "Y" ]]; then
          # 输出提示信息
          echo "Optimizing DNS servers..."
      else
          return
      fi

    # 使用curl检查IPv6连接
    if ping6 -c 1 google.com > /dev/null 2>&1; then
        IPV6_AVAILABLE=true
    else
        IPV6_AVAILABLE=false
    fi

    # 使用curl检查IPv4连接
    if ping -c 1 google.com > /dev/null 2>&1; then
        IPV4_AVAILABLE=true
    else
        IPV4_AVAILABLE=false
    fi
    # 改之前先备份一份
    cp /etc/resolv.conf /etc/resolv.conf.bak
    # 输出备份文件路径
    echo "Backup file: /etc/resolv.conf.bak"

    # 根据可用的IP版本设置DNS
    if [ "$IPV6_AVAILABLE" = true ] && [ "$IPV4_AVAILABLE" = true ]; then
        echo "nameserver 2001:4860:4860::8888" > /etc/resolv.conf
        echo "nameserver 2001:4860:4860::8844" >> /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
        echo "nameserver1.1.1.1" >> /etc/resolv.conf
    elif [ "$IPV4_AVAILABLE" = true ]; then
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver1.1.1.1" >> /etc/resolv.conf
    elif [ "$IPV6_AVAILABLE" = true ]; then
        echo "nameserver 2001:4860:4860::8888" > /etc/resolv.conf
        echo "nameserver 2001:4860:4860::8844" >> /etc/resolv.conf
    else
        echo "No IPv4 or IPv6 connectivity detected. DNS not changed."
    fi
}

# 函数：安装基础工具
install_base_tools() {
   # 检查是否为 Ubuntu 系统
    if [[ "$(lsb_release -is)" == "Ubuntu" ]]; then
      # 密钥列表
      KEYS=("112695A0E562B32A" "54404762BBB6E853" "0E98404D386FA1D9" "6ED0E7B82643E131" "605C66F00D6C9793")

      # 检查并添加密钥
      for KEY in "${KEYS[@]}"; do
        if ! apt-key list | grep -q "$KEY"; then
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$KEY"
        fi
      done
    fi

  # 安装
#  apt update
#  apt upgrade -y
#  apt dist-upgrade -y
#  apt full-upgrade -y
#  apt autoremove -y
#  handle_error $? "Failed to update and upgrade system."
  apt install -y lsof curl git sudo wget net-tools screen iperf3 dnsutils telnet openssl btop
  handle_error $? "Failed to install base tools."
}


# 函数：安装XrayR
install_xrayr() {
    if ! command -v xrayr &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "Do you want to install XrayR? (y/n) " -i y -e install_xrayr
            install_xrayr=${install_xrayr:-y}
        else
            install_xrayr="y"
        fi
        if [[ $install_xrayr == "y" || $install_xrayr == "Y" ]]; then
            wget -N https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/micah123321/XrayR-release/master/install.sh && bash install.sh v1.0 && xrayr update
            handle_error $? "Failed to install XrayR."
        fi
    else
        echo "XrayR is already installed. Skipping installation."
    fi
}

# 函数：安装Fail2Ban
install_fail2ban() {
    if ! command -v fail2ban-client &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "Do you want to install Fail2Ban? (y/n) " -i y -e install_f2b
            install_f2b=${install_f2b:-y}
        else
            install_f2b="y"
        fi
        if [[ $install_f2b == "y" || $install_f2b == "Y" ]]; then
            bash <(curl -L -s https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/setup_fail2ban.sh)
            handle_error $? "Failed to install Fail2Ban."
        fi
    else
        echo "Fail2Ban is already installed. Skipping installation."
    fi
}

# 函数：安装Docker
install_docker() {
      # Check if the system has more than 256MB of RAM
      total_memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
      if [ "$total_memory" -le 262144 ]; then
          echo "Not enough memory to install Docker. Requires more than 256MB of RAM."
          return
      fi
    if ! command -v docker &> /dev/null; then
        if [ "$INTERACTIVE_MODE" == true ]; then
            read -p "Do you want to install Docker? (y/n) " -i y -e install_docker
            install_docker=${install_docker:-y}
        else
            install_docker="y"
        fi
        if [[ $install_docker == "y" || $install_docker == "Y" ]]; then
            wget -qO- get.docker.com | bash
            handle_error $? "Failed to install Docker."
            systemctl enable docker
            systemctl start docker
            curl -L "https://gh-proxy.535888.xyz/https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            handle_error $? "Failed to install Docker Compose."
        fi
    else
        echo "Docker is already installed. Skipping installation."
    fi
}

# 函数：设置时区为上海
set_timezone_shanghai() {
    timedatectl set-timezone Asia/Shanghai
    handle_error $? "Failed to set timezone to Asia/Shanghai."
}

# 函数：开启BBR
enable_bbr() {
  # 如果
  congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
  if [ "$congestion_algorithm" == "bbr" ]; then
      echo "BBR is already enabled. Skipping."
      return
  fi
    curl -o tcpx.sh "https://gh-proxy.535888.xyz/https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
    handle_error $? "Failed to enable BBR."
}

# 函数：清理Debian系统
clean_debian() {
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    # shellcheck disable=SC2046
    apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=50M
    # shellcheck disable=SC2046
    apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
}


# 函数: 获取系统信息
get_system_info() {
    # 尝试使用 lsb_release 获取系统信息
    if command -v lsb_release >/dev/null 2>&1; then
        os_info=$(lsb_release -ds 2>/dev/null)
    else
        # 如果 lsb_release 命令失败，则尝试其他方法
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
    # shellcheck disable=SC2002
    cpu_info=$(cat /proc/cpuinfo | grep "model name" | uniq | awk -F': ' '{print $2}' | sed 's/^[ \t]*//')
    if [ -z "$cpu_info" ]; then
        cpu_info="Unknown"
    fi
}

# 函数: 获取CPU占用率
get_cpu_usage() {
    if [ -f /proc/stat ]; then
        # shellcheck disable=SC2207
        # shellcheck disable=SC2002
        cpu_info=($(cat /proc/stat | grep '^cpu '))
        total_cpu_usage=0
        for (( i=1; i<${#cpu_info[@]}; i++ )); do
            total_cpu_usage=$((total_cpu_usage + ${cpu_info[$i]}))
        done
        idle_cpu_usage=${cpu_info[4]}
        cpu_usage_percent=$((100 - ((100 * idle_cpu_usage) / total_cpu_usage)))
    else
        cpu_usage_percent="Unknown"
    fi
}



display_system_info() {
    # 获取其他系统信息
    hostname=$(hostname)
    kernel_version=$(uname -r)
    cpu_arch=$(uname -m)
    cpu_cores=$(nproc)
    mem_info=$(free -m | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    swap_info=$(free -m | awk 'NR==3{printf "%.2f/%.2f MB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')
    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/)
    country=$(curl -s ipinfo.io/country)
    city=$(curl -s ipinfo.io/city)
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    runtime=$(uptime -p)

    # 显示系统信息
    echo ""
    echo "系统信息查询"
    echo "------------------------"
    echo "主机名: $hostname"
    echo "系统版本: $os_info"
    echo "Linux版本: $kernel_version"
    echo "------------------------"
    echo "CPU架构: $cpu_arch"
    # shellcheck disable=SC2128
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
    # 检查warp命令是否已存在
    if command -v warp &> /dev/null; then
        echo "WARP service is already installed. Skipping download and execution."
        return
    fi

    # 继续交互模式的判断和执行
    if [ "$INTERACTIVE_MODE" == true ]; then
        read -p "Do you want to enable WARP streaming? (y/n) " -i y -e warp_choice
        warp_choice=${warp_choice:-y}
    else
        warp_choice="y"
    fi

    if [[ $warp_choice == "y" || $warp_choice == "Y" ]]; then
        echo "Enabling WARP streaming..."
        wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && chmod +x menu.sh && sudo ./menu.sh e
        handle_error $? "Failed to enable WARP streaming."
    else
        echo "WARP streaming setup skipped."
    fi
}


# 主执行逻辑
{
    check_root
    update_sources_list
    optimize_dns
    install_base_tools
    install_xrayr
    install_docker
    set_timezone_shanghai
#    enable_warp_streaming
    clean_debian
    enable_bbr
    install_fail2ban
    get_system_info
    get_cpu_model
    get_cpu_usage
    display_system_info
    echo "Initialization and optimization complete."
}
