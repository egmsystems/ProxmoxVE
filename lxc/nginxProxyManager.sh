#!/bin/bash
if [ "$VERBOSE" = "yes" ]; then
  STD=""
else STD="silent"; fi
silent() { "$@" >/dev/null 2>&1; }
echo egmPCTcreate
ID=$(pvesh get /cluster/nextid)
PASSWORD="prueba12"
HOSTNAME="nginxProxyManager"
STORAGE="local-lvm"
ROOTFS="4"
MEMORY="1024"
SWAP="512"
NET0="name=eth0,bridge=vmbr0,ip=dhcp"
TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
pct create $ID $TEMPLATE --hostname $HOSTNAME --storage $STORAGE --rootfs $ROOTFS --memory $MEMORY --swap $SWAP --net0 $NET0 --password $PASSWORD
echo "Contenedor creado con ID $ID"
#pct console $ID
#pct enter $ID
$STD = "pct exec $ID"

echo "Actualizsando SO"
$STD apt-get -y update
echo "SO Actualizsado"

echo "Installing Openresty"
$STD wget -qO - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg
$STD echo -e "deb http://openresty.org/package/debian bullseye openresty" >/etc/apt/sources.list.d/openresty.list
$STD apt-get -y install openresty
echo "Installed Openresty"

echo "Installing Node.js"
$STD bash <(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh)
$STD source ~/.bashrc
$STD nvm install 16.20.2
$STD ln -sf /root/.nvm/versions/node/v16.20.2/bin/node /usr/bin/node
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
  $STD wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v2.10.4 -O - | tar -xz
  $STD cd ./nginx-proxy-manager-2.10.4
  echo "Downloaded Nginx Proxy Manager v2.10.4"
else
  echo "Downloading Nginx Proxy Manager v${RELEASE}"
  $STD wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v${RELEASE} -O - | tar -xz
  $STD cd ./nginx-proxy-manager-${RELEASE}
  echo "Downloaded Nginx Proxy Manager v${RELEASE}"
fi
echo "Setting up Enviroment"
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  $STD sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" backend/package.json
  $STD sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" frontend/package.json
else
  $STD sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" backend/package.json
  $STD sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" frontend/package.json
fi
$STD sed -i "s|https://github.com.*source=nginx-proxy-manager|egmsystems|g" frontend/js/app/ui/footer/main.ejs
$STD sed -i "s|\"db\"|\"mariadb\"|" backend/config/default.json
$STD sed -i "s|\"password\": \"npm\"|\"password\": \"Gp7mf1MRru3oMGs\"|" backend/config/default.json
$STD sed -i "s|\"npm\"|\"nginxProxyManager\"|" backend/config/default.json
$STD ln -sf /usr/bin/python3 /usr/bin/python
$STD ln -sf /usr/bin/certbot /opt/certbot/bin/certbot
$STD ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
$STD ln -sf /usr/local/openresty/nginx/ /etc/nginx
$STD NGINX_CONFS=$(find "$(pwd)" -type f -name "*.conf")
for NGINX_CONF in $NGINX_CONFS; do
  $STD sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF"
done
$STD cp -r docker/rootfs/var/www/html/* /var/www/html/
$STD cp -r docker/rootfs/etc/nginx/* /etc/nginx/
$STD cp docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini
$STD cp docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager
$STD ln -sf /etc/nginx/nginx.conf /etc/nginx/conf/nginx.conf
$STD rm -f /etc/nginx/conf.d/dev.conf
$STD chmod -R 777 /var/cache/nginx
$STD chown root /tmp/nginx
$STD echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf);" >/etc/nginx/conf.d/include/resolvers.conf
if [ ! -f /data/nginx/dummycert.pem ] || [ ! -f /data/nginx/dummykey.pem ]; then
  $STD openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" -keyout /data/nginx/dummykey.pem -out /data/nginx/dummycert.pem &>/dev/null
fi
$STD cp -r backend/* /app
$STD cp -r global/* /app/global
echo "Set up Enviroment"

echo "Building Frontend"
$STD cd ./frontend
$STD pnpm install
$STD pnpm upgrade
$STD pnpm run build
$STD cp -r dist/* /app/frontend
$STD cp -r app-images/* /app/frontend/images
echo "Built Frontend"

echo "Initializing Backend"
$STD cat /app/config/default.json
$STD rm -rf /app/config/default.json
if [ ! -f /app/config/production.json ]; then
DB_MYSQL_HOST=192.168.0.70
DB_MYSQL_NAME=nginxProxyManager
DB_MYSQL_USER=nginxProxyManager
DB_MYSQL_PASSWORD=Gp7mf1MRru3oMGs
  $STD echo "
export DB_MYSQL_HOST=$DB_MYSQL_HOST
export DB_MYSQL_NAME="$DB_MYSQL_NAME"
export DB_MYSQL_USER="$DB_MYSQL_USER"
export DB_MYSQL_PASSWORD="$DB_MYSQL_PASSWORD"
" >> /root/.bashrc
  $STD echo "{
  \"database\": {
    \"engine\": \"mysql\",
    \"host\": \"${DB_MYSQL_HOST}\",
    \"name\": \"${DB_MYSQL_NAME}\",
    \"user\": \"${DB_MYSQL_USER}\",
    \"password\": \"${DB_MYSQL_PASSWORD}\",
    \"port\": 3306
  }
}" > /app/config/production.json
  $STD cp /app/config/production.json /app/config/default.json
  $STD cat /app/config/production.json
  $STD rm /data/database.sqlite
fi
$STD cd /app
$STD pnpm install
$STD npm run build
$STD npm start
$STD cat /app/config/default.json
echo "Initialized Backend"

echo "Creating Service"
$STD cat <<'EOF' >/lib/systemd/system/npm.service
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
$STD sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
$STD sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
$STD sed -i 's/include-system-site-packages = false/include-system-site-packages = true/g' /opt/certbot/pyvenv.cfg
$STD systemctl enable -q --now openresty
$STD systemctl enable -q --now npm
echo "Started Services"

echo "Cleaning up"
$STD cd ..
$STD rm -rf nginx-proxy-manager-*
#$STD systemctl restart openresty
$STD apt-get -y autoremove
$STD apt-get -y autoclean
echo "Cleaned"

exit
