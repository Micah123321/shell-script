#!/bin/bash

# 检测是否为 Debian 系统
is_debian() {
    if [ -f /etc/debian_version ]; then
        return 0  # 返回 0 表示是 Debian 系统
    else
        return 1  # 返回 1 表示不是 Debian 系统
    fi
}

# 检查并安装缺失的依赖
install_dependencies() {
    echo "正在检测并安装缺失的依赖..."

    # 检查 ping
    if ! command -v ping &> /dev/null; then
        echo "未安装 ping，正在安装..."
        sudo apt-get update -y
        sudo apt-get install -y iputils-ping
        echo "ping 安装完成"
    else
        echo "ping 已安装"
    fi

    # 检查 awk
    if ! command -v awk &> /dev/null; then
        echo "未安装 awk，正在安装..."
        sudo apt-get install -y gawk
        echo "awk 安装完成"
    else
        echo "awk 已安装"
    fi

    # 检查 bc
    if ! command -v bc &> /dev/null; then
        echo "未安装 bc，正在安装..."
        sudo apt-get install -y bc
        echo "bc 安装完成"
    else
        echo "bc 已安装"
    fi
}

# 显示进度条
show_progress() {
    echo -n "依赖检测中"
    while true; do
        for i in {1..3}; do
            echo -n "."
            sleep 1
        done
        break
    done
    echo " 完成"
}

# 检查并安装依赖
check_dependencies() {
    is_debian
    if [ $? -eq 0 ]; then
        show_progress
        install_dependencies
    else
        echo "本脚本仅支持 Debian 系统"
        exit 1
    fi
}

# 定义各地区的 IP 列表
declare -A ips
ips["北京电信"]="bj-ct-v4.ip.zstaticcdn.com"
ips["天津电信"]="tj-ct-v4.ip.zstaticcdn.com"
ips["河北电信"]="he-ct-v4.ip.zstaticcdn.com"
ips["上海电信"]="sh-ct-v4.ip.zstaticcdn.com"
ips["广东电信"]="gd-ct-v4.ip.zstaticcdn.com"
ips["四川电信"]="sc-ct-v4.ip.zstaticcdn.com"
ips["浙江电信"]="zj-ct-v4.ip.zstaticcdn.com"
ips["江苏电信"]="js-ct-v4.ip.zstaticcdn.com"
ips["辽宁电信"]="ln-ct-v4.ip.zstaticcdn.com"
ips["福建电信"]="fj-ct-v4.ip.zstaticcdn.com"
ips["河北联通"]="he-cu-v4.ip.zstaticcdn.com"
ips["天津联通"]="tj-cu-v4.ip.zstaticcdn.com"
ips["内蒙古联通"]="nm-cu-v4.ip.zstaticcdn.com"
ips["广东联通"]="gd-cu-v4.ip.zstaticcdn.com"
ips["四川联通"]="sc-cu-v4.ip.zstaticcdn.com"
ips["浙江联通"]="zj-cu-v4.ip.zstaticcdn.com"
ips["江苏联通"]="js-cu-v4.ip.zstaticcdn.com"
ips["辽宁联通"]="ln-cu-v4.ip.zstaticcdn.com"
ips["福建联通"]="fj-cu-v4.ip.zstaticcdn.com"
ips["北京联通"]="bj-cu-v4.ip.zstaticcdn.com"
ips["上海联通"]="sh-cu-v4.ip.zstaticcdn.com"
ips["广东移动"]="gd-cm-v4.ip.zstaticcdn.com"
ips["天津移动"]="tj-cm-v4.ip.zstaticcdn.com"
ips["内蒙古移动"]="nm-cm-v4.ip.zstaticcdn.com"
ips["四川移动"]="sc-cm-v4.ip.zstaticcdn.com"
ips["浙江移动"]="zj-cm-v4.ip.zstaticcdn.com"
ips["江苏移动"]="js-cm-v4.ip.zstaticcdn.com"
ips["辽宁移动"]="ln-cm-v4.ip.zstaticcdn.com"
ips["福建移动"]="fj-cm-v4.ip.zstaticcdn.com"
ips["河北移动"]="he-cm-v4.ip.zstaticcdn.com"

# 统计延迟
get_ping_delay() {
    local ip=$1
    result=$(ping -c 4 -q $ip | grep "rtt" | awk -F'/' '{print $5}')
    echo $result
}

# 统计区域延迟
get_region_delay() {
    local region=$1
    local delay_values=()
    local fastest=9999
    local slowest=0
    local total=0
    local count=0

    for ip in "${ips[@]}"; do
        delay=$(get_ping_delay $ip)
        if [[ $delay =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            delay_values+=($delay)
            total=$(echo "$total + $delay" | awk '{print $1 + $2}')
            count=$((count + 1))

            # 计算最快和最慢延迟
            if (( $(echo "$delay < $fastest" | awk '{if ($1 < $2) print 1; else print 0}') )); then
                fastest=$delay
            fi
            if (( $(echo "$delay > $slowest" | awk '{if ($1 > $2) print 1; else print 0}') )); then
                slowest=$delay
            fi
        fi
    done

    # 计算平均延迟
    average=$(echo "$total / $count" | awk '{print $1 / $2}')
    echo "$region: 最快 $fastest ms, 最慢 $slowest ms, 平均 $average ms"
}

# 显示各个区域的延迟情况
get_region_delay "华东地区"
get_region_delay "华南地区"
get_region_delay "华中地区"
get_region_delay "华北地区"
get_region_delay "西南地区"
get_region_delay "西北地区"
get_region_delay "东北地区"

