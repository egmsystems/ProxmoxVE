#!/bin/bash
echo "egmPCTcreate"
ID=$(pvesh get /cluster/nextid)
PASSWORD="prueba12"
VERBOSE="no"
HOSTNAME="nginxProxyManager"
STORAGE="local-lvm"
ROOTFS="4"
MEMORY="1024"
SWAP="512"
NET0="name=eth0,bridge=vmbr0,ip=dhcp"
TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
if [ "$VERBOSE" = "yes" ]; then
  STD=""
else STD="silent"; fi
silent() { "$@" >/dev/null 2>&1; }
pct create $ID $TEMPLATE --hostname $HOSTNAME --storage $STORAGE --rootfs $ROOTFS --memory $MEMORY --swap $SWAP --net0 $NET0 --password $PASSWORD
echo "Contenedor creado con ID $ID"
#pct console $ID
pct start $ID
pct enter $ID
#$STD = "pct exec $ID"

echo "Actualizsando SO"
$STD apt-get -y update
echo "SO Actualizsado"

echo "Installing dependences"
$STD apt-get -y install \
  sudo \
  mc \
  curl \
  gnupg \
  make \
  gcc \
  g++ \
  ca-certificates \
  apache2-utils \
  logrotate \
  build-essential \
  git
echo "Installed dependences"

echo "Installing Python Dependencies"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-cffi \
  python3-certbot \
  python3-certbot-dns-cloudflare
$STD pip3 install certbot-dns-multi
$STD python3 -m venv /opt/certbot/
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
echo "Installed Python Dependencies"

#VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

echo "Installing Openresty"
wget -qO - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg
echo -e "deb http://openresty.org/package/debian bullseye openresty" >/etc/apt/sources.list.d/openresty.list
#$STD apt-get -y update
$STD apt-get -y install openresty
echo "Installed Openresty"

echo "Installing Node.js"
$STD bash <(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh)
$STD source ~/.bashrc
$STD nvm install 16.20.2
# manpath: can't set the locale; make sure $LC_* and $LANG are correct
ln -sf /root/.nvm/versions/node/v16.20.2/bin/node /usr/bin/node
echo "Installed Node.js"

echo "Installing pnpm"
$STD npm install -g pnpm@8.15
echo "Installed pnpm"

RELEASE=$(curl -s https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 3, length($2)-4) }')
read -r -p "Would you like to install an older version (v2.10.4)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  echo "Downloading Nginx Proxy Manager v2.10.4"
  wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v2.10.4 -O - | tar -xz
  cd ./nginx-proxy-manager-2.10.4
  echo "Downloaded Nginx Proxy Manager v2.10.4"
else
  echo "Downloading Nginx Proxy Manager v${RELEASE}"
  wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v${RELEASE} -O - | tar -xz
  cd ./nginx-proxy-manager-${RELEASE}
  echo "Downloaded Nginx Proxy Manager v${RELEASE}"
fi
echo "Setting up Enviroment"
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" backend/package.json
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" frontend/package.json
else
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" backend/package.json
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" frontend/package.json
fi
sed -i "s|https://github.com.*source=nginx-proxy-manager|egmsystems|g" frontend/js/app/ui/footer/main.ejs
sed -i "s|\"db\"|\"mariadb\"|" backend/config/default.json
sed -i "s|\"password\": \"npm\"|\"password\": \"Gp7mf1MRru3oMGs\"|" backend/config/default.json
sed -i "s|\"npm\"|\"nginxProxyManager\"|" backend/config/default.json
ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/certbot /opt/certbot/bin/certbot
ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
ln -sf /usr/local/openresty/nginx/ /etc/nginx
NGINX_CONFS=$(find "$(pwd)" -type f -name "*.conf")
for NGINX_CONF in $NGINX_CONFS; do
  sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF"
done
mkdir -p /var/www/html /etc/nginx/logs
cp -r docker/rootfs/var/www/html/* /var/www/html/
cp -r docker/rootfs/etc/nginx/* /etc/nginx/
cp docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini
cp docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager
ln -sf /etc/nginx/nginx.conf /etc/nginx/conf/nginx.conf
rm -f /etc/nginx/conf.d/dev.conf
mkdir -p /tmp/nginx/body \
  /run/nginx \
  /data/nginx \
  /data/custom_ssl \
  /data/logs \
  /data/access \
  /data/nginx/default_host \
  /data/nginx/default_www \
  /data/nginx/proxy_host \
  /data/nginx/redirection_host \
  /data/nginx/stream \
  /data/nginx/dead_host \
  /data/nginx/temp \
  /var/lib/nginx/cache/public \
  /var/lib/nginx/cache/private \
  /var/cache/nginx/proxy_temp \
  /app \
  /app/frontend \
  /app/frontend/images
chmod -R 777 /var/cache/nginx
chown root /tmp/nginx
echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf);" >/etc/nginx/conf.d/include/resolvers.conf
if [ ! -f /data/nginx/dummycert.pem ] || [ ! -f /data/nginx/dummykey.pem ]; then
  $STD openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" -keyout /data/nginx/dummykey.pem -out /data/nginx/dummycert.pem &>/dev/null
fi
cp -r backend/* /app
cp -r global/* /app/global
echo "Set up Enviroment"

echo "Building Frontend"
cd ./frontend
$STD pnpm install
$STD pnpm upgrade
$STD pnpm run build
cp -r dist/* /app/frontend
cp -r app-images/* /app/frontend/images
echo "Built Frontend"

echo "Initializing Backend"
rm -rf /app/config/default.json
if [ ! -f /app/config/production.json ]; then
  DB_MYSQL_HOST=192.168.0.70
  DB_MYSQL_NAME=nginxProxyManager
  DB_MYSQL_USER=nginxProxyManager
  DB_MYSQL_PASSWORD=Gp7mf1MRru3oMGs
  echo "
export DB_MYSQL_HOST=$DB_MYSQL_HOST
export DB_MYSQL_NAME="$DB_MYSQL_NAME"
export DB_MYSQL_USER="$DB_MYSQL_USER"
export DB_MYSQL_PASSWORD="$DB_MYSQL_PASSWORD"
" >> /root/.bashrc
  cat /root/.bashrc
  echo "{
  \"database\": {
    \"engine\": \"mysql\",
    \"host\": \"${DB_MYSQL_HOST}\",
    \"name\": \"${DB_MYSQL_NAME}\",
    \"user\": \"${DB_MYSQL_USER}\",
    \"password\": \"${DB_MYSQL_PASSWORD}\",
    \"port\": 3306
  }
}" > /app/config/production.json
  cat /app/config/production.json
  #cp /app/config/production.json /app/config/default.json
fi
cd /app
$STD pnpm install
$STD npm run build
$STD npm start
cat /app/config/default.json
echo "Initialized Backend"

echo "Creating Service"
cat <<'EOF' >/lib/systemd/system/npm.service
[Unit]
Description=Nginx Proxy Manager
After=network.target
Wants=openresty.service

[Service]
Type=simple
Environment=NODE_ENV=production
ExecStartPre=-mkdir -p /tmp/nginx/body /data/letsencrypt-acme-challenge
ExecStart=/usr/bin/node index.js --abort_on_uncaught_exception --max_old_space_size=250
WorkingDirectory=/app
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
echo "Created Service"

echo "Starting Services"
sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
sed -i 's/include-system-site-packages = false/include-system-site-packages = true/g' /opt/certbot/pyvenv.cfg
$STD systemctl enable -q --now openresty
$STD systemctl enable -q --now npm
echo "Started Services"

echo "Cleaning up"
cd ..
rm -rf nginx-proxy-manager-*
#$STD systemctl restart openresty
$STD apt-get -y autoremove
$STD apt-get -y autoclean
echo "Cleaned"

shutdown -r 0
#exit
