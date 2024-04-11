# shell-script

## setup_fail2ban

> 一键安装fail2ban，配置sshd防暴力破解

```shell
bash <(curl -L -s https://ghproxy.535888.xyz/https://raw.githubusercontent.com/Micah123321/shell-script/main/setup_fail2ban.sh)
```

### 配置讲解

在Fail2Ban中，`jail.local`
文件用于定义特定的规则，以便Fail2Ban能够监控日志文件中的失败尝试，并根据这些尝试来封禁恶意IP地址。这个文件通常是从`jail.conf`
复制而来的，以便进行自定义设置，而不会在软件包更新时被覆盖。下面是对脚本中`jail.local`文件配置部分的解释：

```bash
[DEFAULT]
ignoreip = 127.0.0.1/8
```

- `[DEFAULT]`部分包含了适用于所有监狱（jail）的默认设置。
- `ignoreip`设置用于定义哪些IP地址不应被Fail2Ban封禁。这里`127.0.0.1/8`表示本地地址不会被封禁，这是一个常见的安全措施。

```bash
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
bantime  = 1d
findtime  = 5m
maxretry = 3
```

- `[sshd]`部分是一个监狱的定义，专门用于监控SSH服务的登录尝试。
- `enabled = true`表示这个监狱是激活状态。
- `port = 22`指定了SSH服务监听的端口号，默认是22。
- `filter = sshd`指定了Fail2Ban使用哪个过滤器来解析日志文件中的登录失败尝试。过滤器定义在`/etc/fail2ban/filter.d/`目录下。
- `logpath = /var/log/auth.log`（对于Debian系）或`logpath = /var/log/secure`
  （对于CentOS系）指定了Fail2Ban监控的日志文件路径。这些路径分别适用于Debian系和CentOS系的系统。
- `bantime = 1d`设置了封禁的时长，这里是1天。封禁期满后，IP地址将被解封。
- `findtime = 5m`指定了Fail2Ban在多长时间内寻找失败尝试的窗口期，这里是5分钟。如果在这个时间段内发现了超过`maxretry`
  次数的失败尝试，那么触发封禁。
- `maxretry = 3`设置了在`findtime`指定的时间窗口内允许的最大失败尝试次数。超过这个次数的失败尝试将导致来源IP被封禁。

通过这些设置，Fail2Ban能够有效地监控SSH登录尝试，并在检测到恶意行为时自动封禁来源IP地址。这样可以有效地保护服务器免受暴力破解的攻击。
