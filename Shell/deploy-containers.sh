#!/bin/bash

# 定义常量
WORK_DIR="debian-homenas"
COMPOSE_DIR="$WORK_DIR/docker-compose"

# 容器配置，格式为 容器名称=下载地址
declare -A containers=(
    [dockge]="https://gitee.com/kekylin/Debian-HomeNAS/raw/main/Docker%20Compose/dockge.yaml"
    [nginx-ui]="https://gitee.com/kekylin/Debian-HomeNAS/raw/main/Docker%20Compose/nginx-ui.yaml"
    [portainer]="https://gitee.com/kekylin/Debian-HomeNAS/raw/main/Docker%20Compose/portainer.yaml"
    [portainer_zh-cn]="https://gitee.com/kekylin/Debian-HomeNAS/raw/main/Docker%20Compose/portainer_zh-cn.yaml"
    [scrutiny]="https://gitee.com/kekylin/Debian-HomeNAS/raw/main/Docker%20Compose/scrutiny.yaml"
)

# 准备工作：检查并创建目录
prepare_directory() {
    [ ! -d "$COMPOSE_DIR" ] && mkdir -p "$COMPOSE_DIR"
}

# 检查容器安装状态
check_container_status() {
    local name=$1
    docker inspect "$name" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "已安装"
    else
        echo "未安装"
    fi
}

# 下载docker compose文件
download_compose_file() {
    local name=$1
    local url=$2
    [ ! -f "$COMPOSE_DIR/$name.yaml" ] && curl -sSL -o "$COMPOSE_DIR/$name.yaml" "$url"
}

# 安装容器
install_container() {
    local name=$1
    local url=$2
    local status=$(check_container_status $name)
    
    if [ "$status" = "未安装" ]; then
        download_compose_file $name $url
        docker compose -p "$name" -f "$COMPOSE_DIR/$name.yaml" up -d
    else
        echo "$name 已安装，跳过安装。"
    fi
}

# 显示菜单并处理用户输入（按照容器名称排序）
show_menu() {
    local index=1
    local choices=()

    echo "菜单："
    # 按照容器名称排序
    sorted_containers=$(for name in "${!containers[@]}"; do echo "$name"; done | sort)
    
    for name in $sorted_containers; do
        local status=$(check_container_status $name)
        echo "$index. $name ($status)"
        choices+=($name)
        ((index++))
    done

    echo "$index. 全部安装"
    echo "0. 退出"
    echo -n "请输入安装的容器编号："
    read choice

    if [ "$choice" -eq 0 ]; then
        exit 0
    elif [ "$choice" -eq "$index" ]; then
        for name in $sorted_containers; do
            install_container $name "${containers[$name]}"
        done
    elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#choices[@]}" ]; then
        local selected_name=${choices[$((choice-1))]}
        install_container $selected_name "${containers[$selected_name]}"
    else
        echo "无效选项，请重新输入。"
        show_menu
    fi
}

# 主程序
main() {
    prepare_directory
    show_menu
}

main
