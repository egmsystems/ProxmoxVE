#!/bin/bash
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/egmsystems/ProxmoxVE/refs/heads/main/lxc/nginxProxyManager.sh)"
echo "egmPCTcreate outter"
ID=$(pvesh get /cluster/nextid)
PASSWORD=""
VERBOSE="no"
HOSTNAME="nginxProxyManager2"
STORAGE="local-lvm"
ROOTFS=4
MEMORY=1024
SWAP=512
NET0="name=eth0,bridge=vmbr0,ip=dhcp"
TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
export DB_MYSQL_HOST="192.168.0.70"
export DB_MYSQL_USER=nginxProxyManager
export DB_MYSQL_PASSWORD=Gp7mf1MRru3oMGs
export DB_MYSQL_NAME=nginxProxyManager
if [ "$VERBOSE" = "yes" ]; then
  export STD=""
else export STD="silent"; fi
silent() { "$@" >/dev/null 2>&1; }
echo "Creando contenedor con ID $ID"
if [ -z "$PASSWORD" ]; then
  pct create $ID $TEMPLATE --hostname $HOSTNAME --storage $STORAGE --rootfs $ROOTFS --memory $MEMORY --swap $SWAP --net0 $NET0
else
  pct create $ID $TEMPLATE --hostname $HOSTNAME --storage $STORAGE --rootfs $ROOTFS --memory $MEMORY --swap $SWAP --net0 $NET0 --password $PASSWORD
fi
#pct console $ID
pct start $ID
export aptproxy = "$(cat /etc/apt/apt.conf.d/00aptproxy)"
pct exec $ID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/egmsystems/ProxmoxVE/refs/heads/main/lxc/create1.sh)"
echo "http://$(hostname)"
