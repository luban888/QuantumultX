#!/bin/bash
set -euo pipefail

# ======= 配置变量 =======
DOMAIN="your.domain.com"     # 改成你的域名
WEBROOT="/var/www/fallback_site"
SITE="/etc/nginx/sites-available/fallback"
# ========================

echo "[1/4] 安装 nginx..."
sudo apt update -y
sudo apt install -y nginx

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
