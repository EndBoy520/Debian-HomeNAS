#!/bin/bash

# 启用向后移植存储库
echo "deb http://deb.debian.org/debian $(. /etc/os-release && echo $VERSION_CODENAME)-backports main" > /etc/apt/sources.list.d/backports.list
# 配置45Drives Repo安装脚本（用于安装Navigator、File Sharing、Identities组件）
curl -sSL https://repo.45drives.com/setup | bash
apt update

# 安装Cockpit及其附属组件（Navigator、File Sharing、Identities组件）
apt install -y -t $(. /etc/os-release && echo $VERSION_CODENAME)-backports cockpit cockpit-pcp
apt install -y cockpit-navigator cockpit-file-sharing cockpit-identities

# 询问是否安装cockpit-machines
read -p "是否安装虚拟机组件？(y/n): " install_machines
if [[ $install_machines == "y" ]]; then
    to_install+=("cockpit-machines")
fi
# 根据用户回答安装组件
for component in "${to_install[@]}"; do
    apt install -y -t $(. /etc/os-release && echo $VERSION_CODENAME)-backports "$component"
done

# 配置首页展示信息
tee /etc/motd > /dev/null <<EOF
我们信任您已经从系统管理员那里了解了日常注意事项。总结起来无外乎这三点：
1、尊重别人的隐私。
2、输入前要先考虑(后果和风险)。
3、权力越大，责任越大。
EOF

# 安装Tuned系统调优工具
apt install tuned -y

# cockpit调优，设置自动注销闲置及Nginx反向代理Cockpit操作。
# 检查/etc/cockpit/cockpit.conf配置文件是否存在，不存在则创建
if [ ! -f "/etc/cockpit/cockpit.conf" ]; then
    touch /etc/cockpit/cockpit.conf

    # 插入初始配置内容
    echo "[Session]" > /etc/cockpit/cockpit.conf
    echo "IdleTimeout=15" >> /etc/cockpit/cockpit.conf
    echo "Banner=/etc/cockpit/issue.cockpit" >> /etc/cockpit/cockpit.conf

    echo -e "\n[WebService]" >> /etc/cockpit/cockpit.conf
    echo "ProtocolHeader = X-Forwarded-Proto" >> /etc/cockpit/cockpit.conf
    echo "ForwardedForHeader = X-Forwarded-For" >> /etc/cockpit/cockpit.conf
    echo "LoginTo = false" >> /etc/cockpit/cockpit.conf
    echo "LoginTitle = HomeNAS" >> /etc/cockpit/cockpit.conf
fi

# 检查/etc/cockpit/issue.cockpit配置文件是否存在，不存在则创建
if [ ! -f "/etc/cockpit/issue.cockpit" ]; then
    echo "基于Debian搭建HomeNAS！" > /etc/cockpit/issue.cockpit
fi

# 检查是否需要设置Cockpit外网访问
read -p "是否设置Cockpit外网访问？(y/n): " response
if [ -z "$response" ] || [ "$response" == "n" ]; then
    # 如果用户不做回应或者回答n，则检查/etc/cockpit/cockpit.conf配置文件是否已经配置了Origins参数
    if [ -f "/etc/cockpit/cockpit.conf" ]; then
        if grep -q "Origins" /etc/cockpit/cockpit.conf; then
            # 如果配置文件中存在Origins参数，则将此行Origins参数删除掉
            sed -i '/Origins/d' /etc/cockpit/cockpit.conf
            echo "已跳过Cockpit外网访问配置，并删除对应外网访问参数。"
        else
            echo "已跳过Cockpit外网访问配置，且检查没有配置外网访问参数。"
        fi
    else
        echo "已跳过Cockpit外网访问配置。"
    fi
else
    # 提示用户输入外网访问域名和端口号
    read -p "请输入Cockpit外网访问域名和端口号： " input_domain

    # 从输入的域名中提取纯域名和端口号
    domain=$(echo "$input_domain" | sed 's#^https\?://##;s#.*://##;s#:[0-9]*$##')
    # 如果用户没有输入端口号，默认使用9090
    if ! echo "$domain" | grep -q ":"; then
        domain="$domain:9090"
    fi

    # 提取当前主机内网IP地址
    internal_ip=$(hostname -I | cut -d' ' -f1)

    # 检查/etc/cockpit/cockpit.conf配置文件是否存在，并进行配置
    if [ -f "/etc/cockpit/cockpit.conf" ]; then
        if ! grep -q "Origins" /etc/cockpit/cockpit.conf; then
            sed -i "/\[WebService\]/a Origins = https://$domain wss://$domain https://$internal_ip:9090" /etc/cockpit/cockpit.conf
        else
            sed -i "s#\(Origins = .*\)#Origins = https://$domain wss://$domain https://$internal_ip:9090#" /etc/cockpit/cockpit.conf
        fi
    fi
fi
echo "Cockpit调优配置完成。"

# 设置Cockpit接管网络配置（网络管理工具由network改为NetworkManager）
setup_network_configuration() {
    local interfaces_file="/etc/network/interfaces"
    
    if [ -f "$interfaces_file" ]; then
        # 注释掉未注释的行
        sed -i '/^[^#].*/ s/^/#/' "$interfaces_file"
    else
        echo "文件 '$interfaces_file' 不存在，跳过操作。"
    fi
}
# 重启Network Manager服务
restart_network_manager() {
    systemctl restart NetworkManager && echo "已重启 Network Manager 服务。"
}
# 执行主程序
setup_network_configuration
restart_network_manager

# 重启cockpit服务
systemctl try-restart cockpit
