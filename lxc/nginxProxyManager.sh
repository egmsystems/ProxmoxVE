#!/bin/bash
echo egmPCTcreate
ID=100
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

apt -y update

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

NGINX_CONFS=$(find "$(pwd)" -type f -name "*.conf")
for NGINX_CONF in $NGINX_CONFS; do
  sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF"
done

sed -i "s|\"db\"|\"mariadb\"|" backend/config/default.json
sed -i "s|\"password\": \"npm\"|\"password\": \"Gp7mf1MRru3oMGs\"|" backend/config/default.json
sed -i "s|\"npm\"|\"nginxProxyManager\"|" backend/config/default.json

pct console $ID
#pct enter $ID
