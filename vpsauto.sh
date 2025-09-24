#!/bin/bash
set -e

# 1、科技Lion脚本安装、防火墙、端口开放、SSH防御、BBR3
install_kejilion(){

    #提示开始安装
    echo "开始安装科技Lion脚本..."

    # 更新 apt 包索引
    sudo apt update -y

    #安装科技Lion脚本
    bash <(curl -sL kejilion.sh)
    echo "科技Lion脚本 已安装成功。"

    #安装nano wget unzip nginx
    k install nano
    k install wget
    k install unzip
    k install nginx
    echo "nano wget unzip nginx 已安装成功。"

    #提示开始安装
    echo "开始安装防火墙..."

    #安装防火墙、开放端口

    read -p "安装完成后请手动-关闭所有端口 操作指令：4  0  (回车确认):" kfhq4
    k fhq
    echo "防火墙已开启成功。"

    k dkdk 22
    k dkdk 80
    k dkdk 443
    k dkdk 8443
    echo "防火墙端口已开启完成"

    #安装SSH防御
    read -p "开启SSH防御需要手动操作： 13  22  1  (回车确认):" SSHFY999
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


# 3、VPN及回落站点专用SSL证书安装
install_VPN_SSL(){

    #提示开始安装
    echo "开始安装VPN及回落站点专用SSL证书..."

    #安装防火墙、开放端口
    k dkdk 22
    k dkdk 80
    k dkdk 443
    k dkdk 8443
    echo "防火墙和端口已开启完成。"

    # 安装SSL证书
    read -p "请输入已解析的VPN域名：" DOMAIN
    k ssl $DOMAIN
    echo "SSL证书已申请成功。"

}


# 4、部署回落站点
install_fallback_site(){
    #提示开始安装
    k install nginx
    echo "开始部署回落站点..."
    read -p "请输入已解析的域名：" DOMAIN
    # 写入 JSON 内容（三行）

### ===== 可配置变量 =====
# DOMAIN="speedtest.lubancube.com"         # 你的域名
# WEBROOT="/var/www/fallback_site"         # 回落站点根目录
# CERT_FILE="/etc/ssl/mycert/fullchain.pem"  # 你“另外申请”的证书路径（可改）
# KEY_FILE="/etc/ssl/mycert/privkey.pem"     # 你“另外申请”的私钥路径（可改）
# 如你将来打算用 LE 的默认路径，也可直接改成：
# CERT_FILE="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
# KEY_FILE="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
### =====================


# ======= 配置变量 =======
# DOMAIN="your.domain.com"     # 改成你的域名
WEBROOT="/var/www/fallback_site"
SITE="/etc/nginx/sites-available/fallback"
# ========================

echo "[1/4] 安装 nginx..."
k install nginx

echo "[2/4] 修正 nginx 主配置 include..."
sudo sed -i 's#include /etc/nginx/sites-enabled/.*;#include /etc/nginx/sites-enabled/*;#' /etc/nginx/nginx.conf || true
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

echo "[3/4] 准备站点目录和内容..."
sudo mkdir -p "${WEBROOT}/.well-known/acme-challenge"
sudo tee "${WEBROOT}/index.html" >/dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Welcome</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: #fafafa; color: #333; }
    header { border-bottom: 1px solid #ddd; margin-bottom: 20px; }
    nav a { margin-right: 15px; text-decoration: none; color: #0366d6; }
    nav a:hover { text-decoration: underline; }
    footer { margin-top: 40px; font-size: 0.9em; color: #777; }
  </style>
</head>
<body>
  <header>
    <h1>Welcome to Our Site</h1>
    <nav>
      <a href="/">Home</a>
      <a href="/about.html">About</a>
      <a href="/contact.html">Contact</a>
    </nav>
  </header>
  <main>
    <h2>Simple Demo Page</h2>
    <p>This is a simple and normal demo website. The server is running properly.</p>
    <p>You can customize this page by editing <code>/var/www/fallback_site/index.html</code>.</p>
  </main>
  <footer>
    <p>&copy; 2025 Example Company. All rights reserved.</p>
  </footer>
</body>
</html>
EOF

# 补充 About 页面
sudo tee "${WEBROOT}/about.html" >/dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>About Us</title></head>
<body>
<h1>About</h1>
<p>This is a sample About page. You can put normal content here.</p>
</body>
</html>
EOF

# 补充 Contact 页面
sudo tee "${WEBROOT}/contact.html" >/dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Contact</title></head>
<body>
<h1>Contact</h1>
<p>For inquiries, please send an email to <a href="mailto:info@example.com">info@example.com</a>.</p>
</body>
</html>
EOF

echo "[4/4] 写入 80 端口 Nginx 配置..."
sudo tee "$SITE" >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    root ${WEBROOT};
    index index.html;

    # ACME http-01 验证路径
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        alias ${WEBROOT}/.well-known/acme-challenge/;
        access_log off;
    }

    # 其它请求 → 回落站点
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

sudo ln -sf "$SITE" /etc/nginx/sites-enabled/fallback
sudo nginx -t && sudo systemctl restart nginx

echo "✅ 部署完成！"
echo "检查： curl -I http://${DOMAIN}"

echo "回落站点部署完成！"
}



# 5、安装trojan-go
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
    read -p "请输入Trojan-Go节点SSL域名：" yourdomain

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
    "fallback_port": 80
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



# 6、测试运行trojan-go
install_ceshi(){
    #提示开始安装
    echo "开始测试运行trojan-go..."
    cd /root/trojan/
    ./trojan-go -config /root/trojan/config.json
    echo "测试部署成功。"
}



# 7、trojan-go 自启和后台保活
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


# 8、VLESS 搭建
install_SUI(){
    #提示开始安装
    echo "开始安装SUI..."

    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)

    echo "SUI 已安装成功。"
}


# 9、SNELL 搭建
install_SNELL(){
    #提示开始安装
    echo "开始安装SNELL..."

    #开放端口
    read -p "防火墙开放SNELL端口:" snellport
    k dkdk $snellport
    echo "SNELL端口已开放成功。"

wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh

    echo "SNELL 已安装成功。"

}





# 主函数
while true; do
    # 主菜单
    echo "版本V1.0。请选择一个操作:"
    echo "1、科技Lion脚本安装、防火墙、端口开放、SSH防御、BBR3"
    echo "2、安装3X_UI"
    echo "3、VPN专用SSL证书安装"
    echo "4、部署回落站点"
    echo "5、安装trojan-go"
    echo "6、测试运行trojan-go"
    echo "7、trojan-go 自启和后台保活"
    echo "8、VLESS 搭建"
    echo "9、SNELL 搭建"
    echo "0、退出"

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
            install_VPN_SSL
            cd /home/
            ;;
        4)
            install_fallback_site
            cd /home/
            ;;
        5)
            install_trojan_go
            cd /home/
            ;;
        6)
            install_ceshi
            cd /root/trojan/
            ;;
        7)
            install_trojan_go2
            cd /root/trojan/
            ;;
        8)
            install_SUI
            cd /
            ;;
        9)
            install_SNELL
            cd /
            ;;
        *)
            echo "无效的选项，请重试。"
            ;;
    esac
done
# 结束脚本
