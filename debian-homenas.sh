#!/bin/bash

# 下载所有脚本文件
wget -O system_init.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/system_init.sh
wget -O install_cockpit.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/install_cockpit.sh
wget -O email_config.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/email_config.sh
wget -O system_security.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/system_security.sh
wget -O install_docker.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/install_docker.sh
wget -O service_checker.sh -q --show-progress https://mirror.ghproxy.com/https://raw.githubusercontent.com/kekylin/Debian-HomeNAS/main/service_checker.sh

# 确保所有脚本都下载成功
if [ $? -eq 0 ]; then
    echo "所有脚本下载完成，开始执行..."
    
    # 依次执行所有下载的脚本
    bash system_init.sh
    bash install_cockpit.sh
    bash email_config.sh
    bash system_security.sh
    bash install_docker.sh
    bash service_checker.sh
else
    echo "下载脚本失败，请检查网络连接或稍后再试。"
    exit 1
fi

exit 0
