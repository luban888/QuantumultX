#!/bin/bash

# 安装3X_UI
install_3x_ui(){
    #提示开始安装
    echo "开始安装3x-ui..."

    # 执行3X-ui安装命令
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

    # 提示安装完成
    echo "x-ui 已安装成功。请手动 1、开启防火墙  2、开放端口  3、开启BBR优化  4、其他前端配置"
}

# 安装docker和nano
install_docker_nano() {
    #提示开始安装nano
    echo "安装nano..."

    # 更新 apt 包索引
    sudo apt update

    # 安装 nano
    sudo apt install -y nano

    #提示开始安装docker
    echo "安装docker..."

    # 安装必要的包
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # 导入 Docker 官方的 GPG 密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # 添加 Docker 仓库
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker CE（社区版）
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # 启动 Docker 服务并设置开机自启
    sudo systemctl enable docker
    sudo systemctl start docker

    #提示开始安装Docker Compose
    echo "安装Docker Compose..."

    #下载最新的 Docker Compose 版本
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    #赋予可执行权限
    sudo chmod +x /usr/local/bin/docker-compose

    # 验证 Docker Compose 版本
    docker-compose --version
}

# 拉取镜像安装nginx proxy manager(主控服务器)
install_nginx_proxy_manager() {

    # 提示开始安装 Nginx Proxy Manager 
   echo "拉取镜像安装 Nginx Proxy Manager (主控服务器)..."

    # 使用 Docker Compose 来安装 Nginx Proxy Manager 首先，创建一个目录来存放配置文件
    mkdir /home/nginx-proxy-manager
    cd /home/nginx-proxy-manager

    # 写入 JSON 内容（三行）
    cat <<EOF > "docker-compose.yml"
version: '3'

services:
  app:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    environment:
      - DB_SQLITE_FILE=/data/database.sqlite
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    ports:
      - "80:80"
      - "443:443"  # 非主控服务器禁止监听443端口，与trojan冲突
      - "81:81"  # 这是 Nginx Proxy Manager 的 Web 界面端口
    networks:
      - nginx-proxy-manager

networks:
  nginx-proxy-manager:
    driver: bridge
EOF

    # 启动 Docker Compose 容器
    docker-compose up -d

    #提示Nginx Proxy Manager安装完成
    echo "Nginx Proxy Manager(主控服务器)安装完成。请访问 http://your_server_ip:81 进行配置。用户名: admin@example.com 密码: changeme"
}

# 拉取镜像安装nginx proxy manager(非主控服务器)
install_nginx_proxy_manager2() {

    # 提示开始安装 Nginx Proxy Manager 
   echo "拉取镜像安装 Nginx Proxy Manager (非主控服务器)..."

    # 使用 Docker Compose 来安装 Nginx Proxy Manager 首先，创建一个目录来存放配置文件
    mkdir /home/nginx-proxy-manager
    cd /home/nginx-proxy-manager

    # 写入 JSON 内容（三行）
    cat <<EOF > "docker-compose.yml"
version: '3'

services:
  app:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    environment:
      - DB_SQLITE_FILE=/data/database.sqlite
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    ports:
      - "80:80"
      - "81:81"  # 这是 Nginx Proxy Manager 的 Web 界面端口
    networks:
      - nginx-proxy-manager

networks:
  nginx-proxy-manager:
    driver: bridge
EOF

    # 启动 Docker Compose 容器
    docker-compose up -d

    #提示Nginx Proxy Manager安装完成
    echo "Nginx Proxy Manager (非主控服务器)安装完成。请访问 http://your_server_ip:81 进行配置。用户名: admin@example.com 密码: changeme"
}

# 安装trojan-go
install_trojan_go() {
    echo "开始安装Trojan-Go..."

    # 更新 apt 包索引
    sudo apt update

    # 安装 unzip
    sudo apt install unzip

    # 开放80端口
    ufw allow 80

    # 开放443端口
    ufw allow 443

    # 开放22端口
    ufw allow 22

    # 安装解压Trojan-Go
    cd /root/
    mkdir trojan
    cd /root/trojan/
    wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
    unzip trojan-go-linux-amd64.zip

    # 读取用户个性化输入
    read -p "请输入节点密码：" yourpassword

    # 写入 JSON 内容（三行）
    cat <<EOF > "docker-compose.yml"
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "18.164.174.61",
  "remote_port": 80,
  "password": [
    "$yourpassword"
  ],
  "disable_http_check": false,
  "udp_timeout": 60,
  "ssl": {
    "cert": "/home/nginx-proxy-manager/letsencrypt/live/npm-1/cert.pem",
    "key": "/home/nginx-proxy-manager/letsencrypt/live/npm-1/privkey.pem",
    "fallback_addr": "18.164.174.61",
    "fallback_port": 80,
    "sni": "m.ctrip.com",
    "alpn": [
      "http/1.1",
      "h2",
      "h3"
    ],
    "session_ticket": true,
    "reuse_session": true
  },
  "fakeip": {
    "enabled": true,
    "fakeip_range": "198.18.0.1/16",
    "default": "198.18.0.1"
  },
  "udp": {
    "enabled": true,
    "timeout": 60
  },
  "forward_proxy": {
    "enabled": true,
    "proxy_addr": "127.0.0.1",
    "proxy_port": 1080,
    "username": "4090",
    "password": "4090"
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "prefer_ipv4": false
  },
  "mux": {
    "enabled": true,
    "concurrency": 8,
    "idle_timeout": 60
  }
}
EOF

    echo "Trojan-Go 已安装成功。请核对配置后使用【/root/trojan/】&【./trojan-go】 启动。"
}

# trojan-go 自启和后台保活
install_trojan_go2() {
    echo "开始配置trojan-go自启和后台保活..."
    cd /root/trojan/
    # 后台运行
    nohup ./trojan-go > trojan-go.log 2>&1 &
    nohup /root/trojan/trojan-go -config /root/trojan/config.json > /root/trojan/trojan-go.log 2>&1 &
    # 自启动
    # 写入 JSON 内容（三行）
    cat <<EOF > "/etc/rc.local"
#!/bin/sh -e
# rc.local
nohup /root/trojan/trojan-go -config /root/trojan/config.json > /root/trojan/trojan-go.log 2>&1 &
exit 0
#替换 /path/to/trojan-go 和 /path/to/config.json 为实际的 Trojan-Go 二进制文件路径和配置文件路径。
EOF
    sudo chmod +x /etc/rc.local
    sudo reboot
    echo "配置trojan-go自启和后台保活完成，正在重启测试"
}

# 订阅编辑函数
install_SUB() {
    echo "开始订阅转换..."
    # 读取用户个性化输入
    read -p "请输入节点密码：" tgpassword
    # 读取用户个性化输入
    read -p "请输入节点名称（EB2-GO-US)：" tgname
    # 读取用户个性化输入
    read -p "请输入节点解析域名（data.xia.us)：" host

    echo "订阅链接如下:"
    echo "trojan://$tgpassword@$host:443?type=tcp&security=tls&fp=&alpn=http%2F1.1%2Ch2%2Ch3&sni=m.ctrip.com&skip-cert-verify=true#$tgname"
}


# 主函数
while true; do
    # 主菜单
    echo "请选择一个操作:"
    echo "1. 安装 3x-ui"
    echo "2. 安装 docker、nano"
    echo "3. 安装 nginx proxy manager(主控服务器)"
    echo "4. 安装 nginx proxy manager(非主控服务器)"
    echo "5. 安装 trojan go"
    echo "6. 安装 trojan go 自启和后台保活"
    echo "7. 安装 订阅节点Sub"
    echo "8. 退出"

    # 获取用户输入
    read -p "请输入对应的选项数字: " choice

    # 根据用户选择执行相应的功能
    case $choice in
        1)
            install_3x_ui
            cd /home/
            ;;
        2)
            install_docker_nano
            cd /home/
            ;;
        3)
            install_nginx_proxy_manager
            cd /home/
            ;;
        4)
            install_nginx_proxy_manager2
            cd /home/
            ;;
        5)
            install_trojan_go
            cd /home/
            ;;
        6)
            install_trojan_go2
            cd /home/
            ;;
        7)
            install_SUB
            cd /home/
            ;;
        8)
            echo "退出脚本。"
            break
            ;;
        *)
            echo "无效的选项，请重试。"
            ;;
    esac
done
# 结束脚本
