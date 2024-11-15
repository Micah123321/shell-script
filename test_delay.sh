#!/bin/bash

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
            total=$(echo "$total + $delay" | bc)
            count=$((count + 1))

            # 计算最快和最慢延迟
            if (( $(echo "$delay < $fastest" | bc -l) )); then
                fastest=$delay
            fi
            if (( $(echo "$delay > $slowest" | bc -l) )); then
                slowest=$delay
            fi
        fi
    done

    average=$(echo "$total / $count" | bc -l)
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

