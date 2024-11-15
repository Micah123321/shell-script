#!/bin/bash

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

# 检查是否以root身份运行
[[ $EUID -ne 0 ]] && su='sudo'

# 处理命令行参数
while getopts ":p:" opt; do
  case $opt in
    p)
      mima=$OPTARG
      ;;
    \?)
      red "无效的选项: -$OPTARG" >&2
      exit 1
      ;;
    :)
      red "选项 -$OPTARG 需要一个参数" >&2
      exit 1
      ;;
  esac
done

# 检查是否提供了密码
if [ -z "$mima" ]; then
  red "请使用 -p 参数指定密码" >&2
  exit 1
fi

# 检查和修改文件属性
lsattr /etc/passwd /etc/shadow >/dev/null 2>&1
chattr -i /etc/passwd /etc/shadow >/dev/null 2>&1
chattr -a /etc/passwd /etc/shadow >/dev/null 2>&1
lsattr /etc/passwd /etc/shadow >/dev/null 2>&1

# 检查SSH配置
prl=`grep PermitRootLogin /etc/ssh/sshd_config`
pa=`grep PasswordAuthentication /etc/ssh/sshd_config`

if [[ -n $prl && -n $pa ]]; then
  echo root:$mima | $su chpasswd root
  $su sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
  $su sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  $su service sshd restart
  green "VPS当前用户名：root"
  green "VPS当前root密码：$mima"
else
  red "当前VPS不支持root账户或无法自定义root密码" && exit 1
fi
