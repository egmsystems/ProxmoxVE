containerId = 111
os = "debian"
version = "12"
TEMPLATE = local:vztmpl/$os-$version-standard_$version.0-1_amd64.gz
password = prueba12
pct create $containerId $TEMPLATE \
--hostname nginxProxyManager \
--storage local-lvm \
--rootfs 4 \
--memory 1024 \
--swap 512 \
--net0 name=eth0,bridge=vmbr0,ip=dhcp \
--password $password

apt -y update
apt -y install nginx

apt -y install -y nodejs
git clone https://github.com/jc21/nginx-proxy-manager.git
cd nginx-proxy-manager
DB_MYSQL_HOST=192.168.0.70
DB_MYSQL_NAME=nginxProxyManager
DB_MYSQL_USER=nginxProxyManager
DB_MYSQL_PASSWORD=Gp7mf1MRru3oMGs
  echo "
export DB_MYSQL_HOST=$DB_MYSQL_HOST
export DB_MYSQL_NAME="$DB_MYSQL_NAME"
export DB_MYSQL_USER="$DB_MYSQL_USER"
export DB_MYSQL_PASSWORD="$DB_MYSQL_PASSWORD"
" > /root/.bashrc
  echo "
{

  \"database\": {
    \"engine\": \"mysql\",
    \"host\": \"${DB_MYSQL_HOST}\",
    \"name\": \"${DB_MYSQL_NAME}\",
    \"user\": \"${DB_MYSQL_USER}\",
    \"password\": \"${DB_MYSQL_PASSWORD}\",
    \"port\": 3306
  }
}" > config/production.json
npm install
npm run build
npm start

cd ..
#rm -r nginx-proxy-manager
