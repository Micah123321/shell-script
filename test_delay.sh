#!/bin/bash

# 检测是否为 Debian 系统
is_debian() {
    if [ -f /etc/debian_version ]; then
        return 0
    else
        return 1
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
    for i in {1..3}; do
        echo -n "."
        sleep 1
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

# 测试单个 IP 的延迟
get_ping_delay() {
    local ip=$1
    local name=$2
    local result_file=$3

    local result=$(ping -c 4 -W 2 -q "$ip" 2>/dev/null | grep "rtt" | awk -F'/' '{print $5}')
    if [ -z "$result" ]; then
        echo "$name: 超时"
        echo "$name timeout" >> "$result_file"
    else
        echo "$name: $result ms"
        echo "$name $result" >> "$result_file"
    fi
}

# 测试运营商延迟
test_isp() {
    local isp=$1
    local isp_en=""
    local result_file

    # 将中文运营商名转换为英文变量名
    case "$isp" in
        "电信") isp_en="ct" ;;
        "联通") isp_en="cu" ;;
        "移动") isp_en="cm" ;;
        *) echo "未知的运营商: $isp"; return 1 ;;
    esac

    echo "正在测试 $isp..."
    echo "----------------------------------------"

    # 创建临时文件存储结果
    result_file="results_${isp_en}.txt"
    > "$result_file"

    # 创建唯一的FIFO管道
    local pipe="/tmp/ping_pipe_${isp_en}_$$"
    rm -f "$pipe" 2>/dev/null
    mkfifo "$pipe" || {
        echo "无法创建FIFO管道: $pipe"
        return 1
    }

    # 使用文件描述符打开管道
    exec 3<>"$pipe"
    rm -f "$pipe"

    # 初始化并发数量的令牌
    local parallel=30
    for ((i=1; i<=$parallel; i++)); do
        echo >&3
    done

    # 并行测试各节点延迟
    for name in "${!ips[@]}"; do
        if [[ $name == *"$isp"* ]]; then
            local ip=${ips[$name]}
            # 读取一个令牌
            read -u3
            {
                # 执行ping测试
                get_ping_delay "$ip" "$name" "$result_file"
                # 释放令牌
                echo >&3
            } &
        fi
    done
    wait

    # 关闭并清理管道
    exec 3>&-

    # 统计结果
    local stats=$(awk '
        !/timeout/ {
            sum += $2
            count++
            if (NR == 1 || $2 < min) min = $2
            if (NR == 1 || $2 > max) max = $2
        }
        END {
            if (count > 0)
                printf "%.2f %.2f %.2f %d", min, max, sum/count, count
            else
                print "0 0 0 0"
        }' "$result_file")

    read -r fastest slowest average count <<< "$stats"

    echo "----------------------------------------"
    if [ "$count" -gt 0 ]; then
        echo "$isp 测试结果:"
        echo "最快: $fastest ms"
        echo "最慢: $slowest ms"
        echo "平均: $average ms"
        echo "有效测试点: $count"
    else
        echo "$isp 测试结果: 所有请求均超时"
    fi

    echo "$fastest $slowest $average $count" > "${isp_en}_summary.txt"

    rm -f "$result_file"
}

# 获取当前机器的 IP 地址
get_current_ip() {
    # 尝试多个方法获取外网 IP
    local ip=""
    # 方法1：使用 curl 访问 ipinfo.io
    ip=$(curl -s ipinfo.io/ip 2>/dev/null)
    if [ -z "$ip" ]; then
        # 方法2：使用 curl 访问 ip.sb
        ip=$(curl -s ip.sb 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        # 方法3：使用 curl 访问 ifconfig.me
        ip=$(curl -s ifconfig.me 2>/dev/null)
    fi
    echo "$ip"
}

# 发送 Telegram 消息
send_telegram_message() {
    # 获取当前机器的 IP
    local current_ip=$(get_current_ip)
    # 检查变量是否存在，如果不存在则设置默认值
    : "${ct_fastest:=0}" "${ct_slowest:=0}" "${ct_average:=0}" "${ct_count:=0}"
    : "${cu_fastest:=0}" "${cu_slowest:=0}" "${cu_average:=0}" "${cu_count:=0}"
    : "${cm_fastest:=0}" "${cm_slowest:=0}" "${cm_average:=0}" "${cm_count:=0}"

    # 构建消息内容
    local message=$(cat <<EOF
当前机器IP: ${current_ip}
电信:最慢: ${ct_slowest} ms 平均: ${ct_average} ms
联通:最慢: ${cu_slowest} ms 平均: ${cu_average} ms
移动:最慢: ${cm_slowest} ms 平均: ${cm_average} ms
测试时间: $(date '+%Y-%m-%d %H:%M:%S')
EOF
)

    local token="7661705291:AAHKbwYjKHjgWkIkicgIldxYsD_Qih6DVkQ"
    local chat_id="6747548442"

    # 发送消息到 Telegram
    curl -s -X POST \
        "https://api.telegram.org/bot${token}/sendMessage" \
        -H 'Content-Type: application/json' \
        -d "{
            \"chat_id\": \"${chat_id}\",
            \"text\": \"$(echo "$message" | sed 's/"/\\"/g')\",
            \"parse_mode\": \"Markdown\"
        }"
}

# 主函数
main() {
    # 检查系统和依赖
    check_dependencies

    # IP 列表部分的代码（替换原来的 declare -A ips 部分）
    declare -A ips
    # 电信节点
    ips["北京电信"]="bj-ct-v4.ip.zstaticcdn.com"
    ips["天津电信"]="tj-ct-v4.ip.zstaticcdn.com"
    ips["河北电信"]="he-ct-v4.ip.zstaticcdn.com"
    ips["山西电信"]="sx-ct-v4.ip.zstaticcdn.com"
    ips["辽宁电信"]="ln-ct-v4.ip.zstaticcdn.com"
    ips["吉林电信"]="jl-ct-v4.ip.zstaticcdn.com"
    ips["黑龙江电信"]="hl-ct-v4.ip.zstaticcdn.com"
    ips["上海电信"]="sh-ct-v4.ip.zstaticcdn.com"
    ips["江苏电信"]="js-ct-v4.ip.zstaticcdn.com"
    ips["浙江电信"]="zj-ct-v4.ip.zstaticcdn.com"
    ips["安徽电信"]="ah-ct-v4.ip.zstaticcdn.com"
    ips["福建电信"]="fj-ct-v4.ip.zstaticcdn.com"
    ips["江西电信"]="jx-ct-v4.ip.zstaticcdn.com"
    ips["山东电信"]="sd-ct-v4.ip.zstaticcdn.com"
    ips["河南电信"]="ha-ct-v4.ip.zstaticcdn.com"
    ips["湖北电信"]="hb-ct-v4.ip.zstaticcdn.com"
    ips["湖南电信"]="hn-ct-v4.ip.zstaticcdn.com"
    ips["广东电信"]="gd-ct-v4.ip.zstaticcdn.com"
    ips["海南电信"]="hi-ct-v4.ip.zstaticcdn.com"
    ips["四川电信"]="sc-ct-v4.ip.zstaticcdn.com"
    ips["贵州电信"]="gz-ct-v4.ip.zstaticcdn.com"
    ips["云南电信"]="yn-ct-v4.ip.zstaticcdn.com"
    ips["陕西电信"]="sn-ct-v4.ip.zstaticcdn.com"
    ips["甘肃电信"]="gs-ct-v4.ip.zstaticcdn.com"
    ips["青海电信"]="qh-ct-v4.ip.zstaticcdn.com"
    ips["内蒙古电信"]="nm-ct-v4.ip.zstaticcdn.com"
    ips["广西电信"]="gx-ct-v4.ip.zstaticcdn.com"
    ips["西藏电信"]="xz-ct-v4.ip.zstaticcdn.com"
    ips["宁夏电信"]="nx-ct-v4.ip.zstaticcdn.com"
    ips["新疆电信"]="xj-ct-v4.ip.zstaticcdn.com"
    ips["重庆电信"]="cq-ct-v4.ip.zstaticcdn.com"

    # 联通节点
    ips["北京联通"]="bj-cu-v4.ip.zstaticcdn.com"
    ips["天津联通"]="tj-cu-v4.ip.zstaticcdn.com"
    ips["河北联通"]="he-cu-v4.ip.zstaticcdn.com"
    ips["山西联通"]="sx-cu-v4.ip.zstaticcdn.com"
    ips["辽宁联通"]="ln-cu-v4.ip.zstaticcdn.com"
    ips["吉林联通"]="jl-cu-v4.ip.zstaticcdn.com"
    ips["黑龙江联通"]="hl-cu-v4.ip.zstaticcdn.com"
    ips["上海联通"]="sh-cu-v4.ip.zstaticcdn.com"
    ips["江苏联通"]="js-cu-v4.ip.zstaticcdn.com"
    ips["浙江联通"]="zj-cu-v4.ip.zstaticcdn.com"
    ips["安徽联通"]="ah-cu-v4.ip.zstaticcdn.com"
    ips["福建联通"]="fj-cu-v4.ip.zstaticcdn.com"
    ips["江西联通"]="jx-cu-v4.ip.zstaticcdn.com"
    ips["山东联通"]="sd-cu-v4.ip.zstaticcdn.com"
    ips["河南联通"]="ha-cu-v4.ip.zstaticcdn.com"
    ips["湖北联通"]="hb-cu-v4.ip.zstaticcdn.com"
    ips["湖南联通"]="hn-cu-v4.ip.zstaticcdn.com"
    ips["广东联通"]="gd-cu-v4.ip.zstaticcdn.com"
    ips["海南联通"]="hi-cu-v4.ip.zstaticcdn.com"
    ips["四川联通"]="sc-cu-v4.ip.zstaticcdn.com"
    ips["贵州联通"]="gz-cu-v4.ip.zstaticcdn.com"
    ips["云南联通"]="yn-cu-v4.ip.zstaticcdn.com"
    ips["陕西联通"]="sn-cu-v4.ip.zstaticcdn.com"
    ips["甘肃联通"]="gs-cu-v4.ip.zstaticcdn.com"
    ips["青海联通"]="qh-cu-v4.ip.zstaticcdn.com"
    ips["内蒙古联通"]="nm-cu-v4.ip.zstaticcdn.com"
    ips["广西联通"]="gx-cu-v4.ip.zstaticcdn.com"
    ips["西藏联通"]="xz-cu-v4.ip.zstaticcdn.com"
    ips["宁夏联通"]="nx-cu-v4.ip.zstaticcdn.com"
    ips["新疆联通"]="xj-cu-v4.ip.zstaticcdn.com"
    ips["重庆联通"]="cq-cu-v4.ip.zstaticcdn.com"

    # 移动节点
    ips["北京移动"]="bj-cm-v4.ip.zstaticcdn.com"
    ips["天津移动"]="tj-cm-v4.ip.zstaticcdn.com"
    ips["河北移动"]="he-cm-v4.ip.zstaticcdn.com"
    ips["山西移动"]="sx-cm-v4.ip.zstaticcdn.com"
    ips["辽宁移动"]="ln-cm-v4.ip.zstaticcdn.com"
    ips["吉林移动"]="jl-cm-v4.ip.zstaticcdn.com"
    ips["黑龙江移动"]="hl-cm-v4.ip.zstaticcdn.com"
    ips["上海移动"]="sh-cm-v4.ip.zstaticcdn.com"
    ips["江苏移动"]="js-cm-v4.ip.zstaticcdn.com"
    ips["浙江移动"]="zj-cm-v4.ip.zstaticcdn.com"
    ips["安徽移动"]="ah-cm-v4.ip.zstaticcdn.com"
    ips["福建移动"]="fj-cm-v4.ip.zstaticcdn.com"
    ips["江西移动"]="jx-cm-v4.ip.zstaticcdn.com"
    ips["山东移动"]="sd-cm-v4.ip.zstaticcdn.com"
    ips["河南移动"]="ha-cm-v4.ip.zstaticcdn.com"
    ips["湖北移动"]="hb-cm-v4.ip.zstaticcdn.com"
    ips["湖南移动"]="hn-cm-v4.ip.zstaticcdn.com"
    ips["广东移动"]="gd-cm-v4.ip.zstaticcdn.com"
    ips["海南移动"]="hi-cm-v4.ip.zstaticcdn.com"
    ips["四川移动"]="sc-cm-v4.ip.zstaticcdn.com"
    ips["贵州移动"]="gz-cm-v4.ip.zstaticcdn.com"
    ips["云南移动"]="yn-cm-v4.ip.zstaticcdn.com"
    ips["陕西移动"]="sn-cm-v4.ip.zstaticcdn.com"
    ips["甘肃移动"]="gs-cm-v4.ip.zstaticcdn.com"
    ips["青海移动"]="qh-cm-v4.ip.zstaticcdn.com"
    ips["内蒙古移动"]="nm-cm-v4.ip.zstaticcdn.com"
    ips["广西移动"]="gx-cm-v4.ip.zstaticcdn.com"
    ips["西藏移动"]="xz-cm-v4.ip.zstaticcdn.com"
    ips["宁夏移动"]="nx-cm-v4.ip.zstaticcdn.com"
    ips["新疆移动"]="xj-cm-v4.ip.zstaticcdn.com"
    ips["重庆移动"]="cq-cm-v4.ip.zstaticcdn.com"

    # 测试各运营商
    # 并行测试三个运营商
    test_isp "电信" &
    pid1=$!
    test_isp "联通" &
    pid2=$!
    test_isp "移动" &
    pid3=$!

    # 等待所有测试完成
    wait $pid1 $pid2 $pid3

    # 读取结果并设置变量
    if [ -f "ct_summary.txt" ]; then
        read ct_fastest ct_slowest ct_average ct_count < ct_summary.txt
    fi
    if [ -f "cu_summary.txt" ]; then
        read cu_fastest cu_slowest cu_average cu_count < cu_summary.txt
    fi
    if [ -f "cm_summary.txt" ]; then
        read cm_fastest cm_slowest cm_average cm_count < cm_summary.txt
    fi

    # 删除临时汇总文件
    rm -f ct_summary.txt cu_summary.txt cm_summary.txt

    # 发送汇总消息
    send_telegram_message
}

# 运行主函数
main
