#!/bin/bash
set -e

# 1、科技Lion脚本安装、防火墙、端口开放、SSH防御、BBR3
install_kejilion(){

    #提示开始安装
    echo "开始安装科技Lion脚本..."

    # 更新 apt 包索引
    sudo apt update

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

    read -p "安装完成后-请手动关闭所有端口-操作指令-4-0" kfhq4
    k fhq
    echo "防火墙已开启成功。"

    k dkdk 22
    k dkdk 80
    k dkdk 443
    k dkdk 8443
    echo "防火墙端口已开启完成"

    #安装SSH防御
    read -p "开启SSH防御需要手动操作，k-13-22-1：" SSHFY999
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
WEBROOT="/var/www/fallback_site"         # 回落站点根目录
# CERT_FILE="/etc/ssl/mycert/fullchain.pem"  # 你“另外申请”的证书路径（可改）
# KEY_FILE="/etc/ssl/mycert/privkey.pem"     # 你“另外申请”的私钥路径（可改）
# 如你将来打算用 LE 的默认路径，也可直接改成：
CERT_FILE="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
KEY_FILE="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
### =====================

SITE80="/etc/nginx/sites-available/fallback-80"
SITE443X="/etc/nginx/sites-available/fallback-1234"
EN80="/etc/nginx/sites-enabled/fallback-80"
EN443X="/etc/nginx/sites-enabled/fallback-1234"

echo "[1/6] 安装 nginx（如已安装会跳过）..."
apt update
apt install -y nginx >/dev/null

echo "[2/6] 修正 nginx.conf include（避免默认站点缺失报错）..."
sed -i 's#include /etc/nginx/sites-enabled/.*;#include /etc/nginx/sites-enabled/*;#' /etc/nginx/nginx.conf || true
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

echo "[3/6] 准备站点文件..."
mkdir -p "${WEBROOT}/.well-known/acme-challenge"
cat > "${WEBROOT}/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><title>Fallback Site</title>
<style>body{font-family:Arial,Helvetica,sans-serif;margin:48px}a{color:#0a66c2;text-decoration:none;margin-right:12px}</style>
</head><body>
<nav><a href="/">Home</a><a href="/about.html">About</a><a href="/blog.html">Blog</a><a href="/contact.html">Contact</a></nav>
<h1>Trojan-Go Fallback</h1>
<p>If you see this page, HTTP fallback is working.</p>
</body></html>
EOF
echo "<h1>About</h1>"   > "${WEBROOT}/about.html"
echo "<h1>Blog</h1>"    > "${WEBROOT}/blog.html"
echo "<h1>Contact</h1>" > "${WEBROOT}/contact.html"

echo "[4/6] 写入 80 端口（HTTP 回落 + ACME 验证）配置..."
cat > "$SITE80" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root ${WEBROOT};
    index index.html;

    # ACME http-01 验证路径（如将来需要）
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        alias ${WEBROOT}/.well-known/acme-challenge/;
        access_log off;
    }

    # 其它请求 → 静态站点（回落伪装）
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
ln -sf "$SITE80" "$EN80"

echo "[5/6] 可选：写入 1234 端口（HTTPS 回落）配置文件（稍后再决定是否启用）..."
cat > "$SITE443X" <<EOF
server {
    listen 1234 ssl;
    server_name ${DOMAIN};

    ssl_certificate     ${CERT_FILE};
    ssl_certificate_key ${KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;

    root ${WEBROOT};
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

echo "[6/6] 启动/重载 Nginx，仅启用 80；若检测到证书文件存在再启用 1234..."
nginx -t
systemctl restart nginx

if [[ -s "${CERT_FILE}" && -s "${KEY_FILE}" ]]; then
  echo "[检测] 发现证书与私钥文件，启用 1234 HTTPS 回落..."
  ln -sf "$SITE443X" "$EN443X"
  nginx -t && systemctl reload nginx
else
  echo "[提示] 尚未找到证书："
  echo "  CERT_FILE=${CERT_FILE}"
  echo "  KEY_FILE=${KEY_FILE}"
  echo "已仅启用 80（HTTP 回落）。当你把证书放到以上路径后，执行："
  echo "  ln -sf ${SITE443X} ${EN443X} && nginx -t && systemctl reload nginx"
fi

echo "—— 状态检查 ——"
ss -ltnp | grep -E ':80|:1234' || true

cat <<'END_NOTE'

✅ 完成（不内置证书申请）：

- 80 端口：HTTP 回落 + 预留 ACME 验证路径（/.well-known/acme-challenge/）
- 1234 端口：HTTPS 回落（只有在检测到你已放好证书后才会启用）
- 如稍后才放证书：把文件放到脚本中的 CERT_FILE/KEY_FILE 路径，然后运行：
    ln -sf /etc/nginx/sites-available/fallback-1234 /etc/nginx/sites-enabled/fallback-1234
    nginx -t && systemctl reload nginx

📌 Trojan-Go（示例）：
"fallbacks": [
  { "dest": "127.0.0.1:80",   "alpn": ["http/1.1"] },
  { "dest": "127.0.0.1:1234", "alpn": ["http/1.1"] }
]

注意：
- 在你启用 1234 前，请先只保留 80 作为回落，避免 connect refused。
- 若你使用的是自签名或第三方签发的证书，把 CERT_FILE/KEY_FILE 改成对应路径即可。
- 不建议在 80 上做 301 到 443，因为 443 通常留给 Trojan-Go 主服务。

END_NOTE
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

wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh

    echo "SNELL 已安装成功。"

    #开放端口
    read -p "SNELL端口" snellport
    k dkdk $snellport
    echo "SNELL端口已开放成功。"

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
