#!/bin/bash
echo egmPCTcreate
ID=100
HOSTNAME="nginxProxyManager"
STORAGE="local-lvm"
ROOTFS="8"
MEMORY="1024"
SWAP="512"
NET0="name=eth0,bridge=vmbr0,ip=dhcp"
PASSWORD="mi_contraseña"
TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.gz"
pct create $ID $TEMPLATE --hostname $HOSTNAME --storage $STORAGE --rootfs $ROOTFS --memory $MEMORY --swap $SWAP --net0 $NET0 --password $PASSWORD
echo "Contenedor creado con ID $ID"

apt -y update
