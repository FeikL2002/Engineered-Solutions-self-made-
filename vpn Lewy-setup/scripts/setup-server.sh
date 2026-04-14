#!/usr/bin/env bash
set -euo pipefail

WG_IF="wg0"
WG_PORT="51820"
WG_ADDR="10.66.66.1/24"
WG_DNS="10.66.66.1"
ADGUARD_WORK="/opt/adguardhome/work"
ADGUARD_CONF="/opt/adguardhome/conf"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root or with sudo."
  exit 1
fi

PUBLIC_IF="$(ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')"
SERVER_PUBLIC_IP="$(curl -4 -fsS https://ifconfig.me || true)"

if [[ -z "${PUBLIC_IF}" ]]; then
  echo "Could not detect the public network interface."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wireguard iptables-persistent docker.io curl qrencode

systemctl enable --now docker

mkdir -p /etc/wireguard/clients
chmod 700 /etc/wireguard /etc/wireguard/clients

if [[ ! -f /etc/wireguard/server_private.key ]]; then
  umask 077
  wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
fi

SERVER_PRIV="$(cat /etc/wireguard/server_private.key)"

cat >/etc/sysctl.d/99-wireguard-forward.conf <<'SYSCTL'
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
SYSCTL
sysctl --system >/dev/null

cat >/etc/wireguard/${WG_IF}.conf <<WGCONF
[Interface]
Address = ${WG_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
SaveConfig = true
PostUp = iptables -A FORWARD -i ${WG_IF} -j ACCEPT; iptables -A FORWARD -o ${WG_IF} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${PUBLIC_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_IF} -j ACCEPT; iptables -D FORWARD -o ${WG_IF} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${PUBLIC_IF} -j MASQUERADE
WGCONF

chmod 600 /etc/wireguard/${WG_IF}.conf
systemctl enable --now wg-quick@${WG_IF}

mkdir -p "${ADGUARD_WORK}" "${ADGUARD_CONF}"

if ! docker ps -a --format '{{.Names}}' | grep -qx adguardhome; then
  docker pull adguard/adguardhome
  docker run -d \
    --name adguardhome \
    --restart unless-stopped \
    --network host \
    -v "${ADGUARD_WORK}:/opt/adguardhome/work" \
    -v "${ADGUARD_CONF}:/opt/adguardhome/conf" \
    adguard/adguardhome
else
  docker start adguardhome || true
fi

echo
echo "WireGuard server public key:"
cat /etc/wireguard/server_public.key
echo
echo "Open AdGuard Home setup at: http://${SERVER_PUBLIC_IP:-YOUR_SERVER_IP}:3000"
echo
echo "Firewall:"
echo "  Open UDP ${WG_PORT} to the server."
echo "  Open TCP 3000 temporarily for the AdGuard setup UI."
echo "  Keep port 53 closed to the public internet unless you explicitly want public DNS."
echo
echo "In the AdGuard setup wizard:"
echo "  • Bind DNS to 0.0.0.0:53"
echo "  • Keep the default blocklists enabled"
echo "  • Use the server as its own VPN DNS endpoint (${WG_DNS})"
