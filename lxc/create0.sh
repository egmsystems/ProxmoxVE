#!/bin/bash
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/egmsystems/ProxmoxVE/refs/heads/main/lxc/nginxProxyManager.sh)"
echo "egmPCTcreate outter"
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
pct exec $ID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/egmsystems/ProxmoxVE/refs/heads/main/lxc/create1.sh)"
