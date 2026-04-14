#!/usr/bin/env bash
set -euo pipefail

WG_IF="wg0"
WG_SERVER_CONF="/etc/wireguard/${WG_IF}.conf"
CLIENT_DIR="/etc/wireguard/clients"
SERVER_PUB_KEY_FILE="/etc/wireguard/server_public.key"
DEFAULT_PORT="51820"
DEFAULT_DNS="10.66.66.1"
SUBNET_PREFIX="10.66.66"
START_HOST="2"
END_HOST="254"

usage() {
  cat <<USAGE
Usage:
  sudo bash scripts/add-client.sh <client-name> [server-endpoint]

Examples:
  sudo bash scripts/add-client.sh iphone vpn.example.com
  sudo bash scripts/add-client.sh laptop 203.0.113.10
  sudo bash scripts/add-client.sh tablet
USAGE
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script as root or with sudo."
    exit 1
  fi
}

validate_name() {
  local name="$1"
  if [[ ! "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Client name must contain only letters, numbers, underscores, or hyphens."
    exit 1
  fi
}

get_server_endpoint() {
  local provided="${1:-}"
  if [[ -n "${provided}" ]]; then
    printf '%s\n' "${provided}"
    return
  fi

  local detected
  detected="$(curl -4 -fsS https://ifconfig.me || true)"
  if [[ -z "${detected}" ]]; then
    echo "Could not auto-detect the public endpoint. Pass it as the second argument."
    exit 1
  fi
  printf '%s\n' "${detected}"
}

next_available_ip() {
  local host candidate
  for host in $(seq "${START_HOST}" "${END_HOST}"); do
    candidate="${SUBNET_PREFIX}.${host}"
    if ! grep -q "${candidate}/32" "${WG_SERVER_CONF}" 2>/dev/null; then
      printf '%s\n' "${candidate}"
      return
    fi
  done
  echo "No available client IPs remain in ${SUBNET_PREFIX}.0/24."
  exit 1
}

append_peer() {
  local client_name="$1"
  local client_pub="$2"
  local psk="$3"
  local client_ip="$4"

  cat >>"${WG_SERVER_CONF}" <<PEER

# ${client_name}
[Peer]
PublicKey = ${client_pub}
PresharedKey = ${psk}
AllowedIPs = ${client_ip}/32
PEER
}

reload_wireguard() {
  if command -v wg >/dev/null 2>&1 && ip link show "${WG_IF}" >/dev/null 2>&1; then
    wg syncconf "${WG_IF}" <(wg-quick strip "${WG_IF}")
  else
    systemctl restart "wg-quick@${WG_IF}"
  fi
}

main() {
  require_root

  if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 1
  fi

  local client_name="$1"
  local endpoint
  endpoint="$(get_server_endpoint "${2:-}")"

  validate_name "${client_name}"

  if [[ ! -f "${WG_SERVER_CONF}" ]]; then
    echo "Server config not found at ${WG_SERVER_CONF}. Run setup-server.sh first."
    exit 1
  fi

  if [[ ! -f "${SERVER_PUB_KEY_FILE}" ]]; then
    echo "Server public key file not found at ${SERVER_PUB_KEY_FILE}."
    exit 1
  fi

  mkdir -p "${CLIENT_DIR}"
  chmod 700 /etc/wireguard "${CLIENT_DIR}"

  local client_conf="${CLIENT_DIR}/${client_name}.conf"
  if [[ -f "${client_conf}" ]]; then
    echo "Client config already exists: ${client_conf}"
    exit 1
  fi

  umask 077
  local client_priv client_pub client_psk client_ip server_pub
  client_priv="$(wg genkey)"
  client_pub="$(printf '%s' "${client_priv}" | wg pubkey)"
  client_psk="$(wg genpsk)"
  client_ip="$(next_available_ip)"
  server_pub="$(cat "${SERVER_PUB_KEY_FILE}")"

  append_peer "${client_name}" "${client_pub}" "${client_psk}" "${client_ip}"
  reload_wireguard

  cat >"${client_conf}" <<CONF
[Interface]
PrivateKey = ${client_priv}
Address = ${client_ip}/32
DNS = ${DEFAULT_DNS}

[Peer]
PublicKey = ${server_pub}
PresharedKey = ${client_psk}
Endpoint = ${endpoint}:${DEFAULT_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
CONF

  chmod 600 "${client_conf}"

  echo
  echo "Client created: ${client_name}"
  echo "Config path: ${client_conf}"
  echo "VPN address: ${client_ip}/32"
  echo "Endpoint: ${endpoint}:${DEFAULT_PORT}"
  echo
  echo "QR code:"
  qrencode -t ANSIUTF8 < "${client_conf}" || true
  echo
  echo "Import the config file into the WireGuard app on the target device."
}

main "$@"
