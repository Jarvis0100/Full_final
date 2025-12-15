#!/bin/bash
set -euo pipefail

### CONFIG ###
WORKDIR="$PWD/pg16_ha_offline_repo"
RPMDIR="$WORKDIR/rpms"
WHEELDIR="$WORKDIR/pip_wheels"
ETCDDIR="$WORKDIR/etcd"

echo "=== Building PostgreSQL 16.10 HA Offline Repo ==="

### CLEAN OLD ###
rm -rf "$WORKDIR"
mkdir -p "$RPMDIR" "$WHEELDIR" "$ETCDDIR"

### TOOLS ###
dnf -y install dnf-plugins-core createrepo_c wget python3-pip

### ENABLE PGDG ###
dnf install -y \
https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

dnf config-manager --disable '*testing*'
dnf module disable postgresql -y || true

### RPM PACKAGES (ONLY WHAT EXISTS) ###
RPM_PKGS=(
postgresql16-16.10*
postgresql16-server-16.10*
postgresql16-contrib-16.10*
postgresql16-libs-16.10*
patroni
patroni-etcd
python3-pip
python3-psycopg2
gcc
gcc-c++
python3-devel
glibc-devel
glibc-headers
kernel-headers
libxcrypt-devel
haproxy
keepalived
ipvsadm
net-snmp-libs
net-tools
bind-utils
telnet
nmap-ncat
lsof
psmisc
wget
tar
sysstat
iotop
htop
)

echo "=== Downloading RPM packages ==="
dnf download --resolve --alldeps --downloaddir="$RPMDIR" "${RPM_PKGS[@]}"

### PYTHON WHEELS (REPLACES MISSING RPMs) ###
WHEEL_PKGS=(
click
prettytable
ydiff
dnspython
python-dateutil
requests
urllib3
chardet
idna
six
)

echo "=== Downloading Python wheels ==="
pip3 download --only-binary=:all: -d "$WHEELDIR" "${WHEEL_PKGS[@]}"

### ETCD ###
echo "=== Downloading etcd 3.5.16 ==="
wget -q -O "$ETCDDIR/etcd-v3.5.16-linux-amd64.tar.gz" \
https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-amd64.tar.gz

### BUILD REPO METADATA ###
echo "=== Creating repo metadata ==="
createrepo_c "$RPMDIR"

### PACKAGE OUTPUT ###
cd "$(dirname "$WORKDIR")"
tar -czf pg16_ha_offline_repo.tar.gz "$(basename "$WORKDIR")"

echo "=== DONE: Offline repo created ==="
echo "Output file: pg16_ha_offline_repo.tar.gz"

