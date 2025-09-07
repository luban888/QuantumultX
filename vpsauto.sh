#!/bin/bash

# 1、科技Lion脚本
install_kejilion(){

    #提示开始安装
    echo "开始安装科技Lion脚本..."

    # 更新 apt 包索引
    sudo apt update

    #安装科技Lion脚本
    bash <(curl -sL kejilion.sh)
    echo "科技Lion脚本 已安装成功。请手动 1、开启ssh防御和防火墙  2、开放端口  3、开启BBR3优化  4、其他前端配置"

    #安装nano wget unzip nginx
    k install nano
    k install wget
    k install unzip
    k install nginx
    echo "nano wget unzip nginx 已安装成功。"

    # 安装SSL证书
    read -p "请输入已解析的域名：" ssldomin
    k ssl $ssldomin
    echo "SSL证书已申请成功。"

    #安装防火墙、开放端口
    k fhq
    k dkdk 22
    k dkdk 80
    k dkdk 443
    k dkdk 8443
    echo "防火墙和端口已开启完成。"

    #安装SSH防御
    echo "SSH防御需要手动操作，k-13-22-1"
    k
    echo "SSH防御已开启成功。"

    #安装BBR3加速
    k bbr3
    echo "BBR3加速已安装成功。"

}



# 2、安装3X_UI
install_3x_ui(){
    #提示开始安装
    echo "开始安装3x-ui..."

    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    echo "x-ui 已安装成功。"
}



# 3、部署回落站点
install_huiluo(){
    #提示开始安装
    echo "开始部署回落站点..."

    k install nginx

    cd /etc/nginx/conf.d/

    read -p "请输入已解析的域名：" yourssldomain
    # 写入 JSON 内容（三行）
    cat <<EOF > "http_fallback.conf"

server {
    listen 80;
    server_name $yourssldomain;

    # ACME 验证目录
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # 普通 http 回落页面
    location / {
        root /var/www/html;
        index index.html;
    }
}

EOF

    sudo mkdir -p /var/www/html
    echo "This is HTTP fallback site (port 80)" | sudo tee /var/www/html/index.html


    cd /etc/nginx/conf.d/
    # 写入 JSON 内容（三行）
    cat <<EOF > "https_fallback.conf"

server {
    listen 1234 ssl;
    server_name $yourssldomain;

    ssl_certificate /etc/letsencrypt/live/$yourssldomain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$yourssldomain/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/https_fallback;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}

EOF

    sudo mkdir -p /var/www/https_fallback
    echo "This is HTTPS fallback site (port 1234)" | sudo tee /var/www/https_fallback/index.html

    sudo nginx -t
    sudo systemctl restart nginx
    echo "回落站点已部署成功。"
}



# 4、安装trojan-go
install_trojan_go() {
    echo "开始安装Trojan-Go..."

    # 开放端口
    k dkdk 22
    k dkdk 80
    k dkdk 443
    k dkdk 8443
    k install nano
    k install wget
    k install unzip

    # 安装解压Trojan-Go
    cd /root/
    mkdir trojan
    cd /root/trojan/
    wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
    unzip trojan-go-linux-amd64.zip

    # 读取用户个性化端口
    read -p "请输入Trojan-Go节点端口：" yourport
    # 读取用户个性化密码
    read -p "请输入Trojan-Go节点密码：" yourpassword
    # 读取用户个性化域名
    read -p "请输入Trojan-Go节点域名：" yourdomain

    cd /root/trojan/
    # 写入 JSON 内容（三行）
    cat <<EOF > "config.json"

{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": $yourport,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "disable_http_check": false,
  "log_level": 1,
  "log_file": "",
  "password": ["$yourpassword"],
  "udp_timeout": 120,
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "/etc/letsencrypt/live/$yourdomain/fullchain.pem",
    "key": "/etc/letsencrypt/live/$yourdomain/privkey.pem",
    "sni": "m.ctrip.com",
    "alpn": ["http/1.1","h2"],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "<html><body>404 Not Found</body></html>",
    "fallback_addr": "127.0.0.1",
    "fallback_port": 1234
  },
  "udp": {
    "enabled": true,
    "timeout": 120
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
  },
  "forward_proxy": {
    "enabled": true,
    "proxy_addr": "127.0.0.1",
    "proxy_port": 1080,
    "username": "1080",
    "password": "1080"
  }
}

EOF

    echo "Trojan-Go 已安装成功。"
    # 读取用户个性化节点名称
    read -p "请输入Trojan-Go节点名称：" tgname
    echo "订阅链接如下:"
    echo "trojan://$yourpassword@$yourdomain:$yourport?type=tcp&security=tls&fp=&alpn=http%2F1.1%2Ch2&sni=m.ctrip.com&skip-cert-verify=true#$tgname"
}



# 5、测试运行trojan-go
install_ceshi(){
    #提示开始安装
    echo "开始测试运行trojan-go..."
    cd /root/trojan/
    ./trojan-go -config /root/trojan/config.json
    echo "测试部署成功。"
}



# 6、trojan-go 自启和后台保活
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



# 主函数
while true; do
    # 主菜单
    echo "请选择一个操作:"
    echo "1. 安装 科技Lion脚本并配置防御 防火墙 证书 BBR2"
    echo "2. 安装 3x-ui 面板"
    echo "3. 安装 trojan go 回落站点"
    echo "4. 安装 trojan go 主程序"
    echo "5. 测试 trojan go 主程序"
    echo "6. 安装 trojan go 自启和后台保活"
    echo "0. 退出"

    # 获取用户输入
    read -p "请输入对应的选项数字: " choice

    # 根据用户选择执行相应的功能
    case $choice in
        0)
            echo "退出脚本。"
            break
            ;;
        1)
            install_kejilion
            cd /
            ;;
        2)
            install_3x_ui
            cd /home/
            ;;
        3)
            install_huiluo
            cd /home/
            ;;
        4)
            install_trojan_go
            cd /home/
            ;;
        5)
            install_ceshi
            cd /home/
            ;;
        6)
            install_trojan_go2
            cd /root/trojan/
            ;;
        7)
            echo "退出脚本。"
            break
            ;;
        *)
            echo "无效的选项，请重试。"
            ;;
    esac
done
# 结束脚本
