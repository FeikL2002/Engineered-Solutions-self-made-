# WireGuard + AdGuard Home VPN Kit

A GitHub-ready Bash project for deploying a self-hosted WireGuard VPN server with AdGuard Home for DNS filtering, then generating client profiles for phones, laptops, and tablets.

This repo was built from two uploaded files:

- `setup-server.sh`, which installs and configures WireGuard, enables IP forwarding, sets NAT rules, starts `wg-quick`, and launches AdGuard Home in Docker.
- `add-client.sh`, which in the uploaded version only contained example commands, so a complete client provisioning script was added here to make the repository usable.

## Features

- One-command WireGuard server bootstrap
- AdGuard Home deployment via Docker using host networking
- Automatic IP forwarding and NAT setup
- Client config generation with QR codes for mobile devices
- Per-client config files stored under `/etc/wireguard/clients`
- Safer GitHub layout with docs, workflow, and shell scripts separated clearly

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── shellcheck.yml
├── docs/
│   └── SECURITY-NOTES.md
├── scripts/
│   ├── add-client.sh
│   └── setup-server.sh
├── .gitignore
└── README.md
```

## What This Project Does

### `scripts/setup-server.sh`

This script is intended to run on a Debian or Ubuntu server as root. It:

1. Installs WireGuard, Docker, `iptables-persistent`, `curl`, and `qrencode`
2. Generates WireGuard server keys if they do not already exist
3. Enables IPv4 and IPv6 forwarding
4. Writes `/etc/wireguard/wg0.conf`
5. Enables and starts `wg-quick@wg0`
6. Deploys AdGuard Home in Docker using host networking
7. Prints the server public key and AdGuard setup instructions

### `scripts/add-client.sh`

This script creates a WireGuard client profile by:

1. Generating a private key, public key, and preshared key for the client
2. Assigning the next available address in the VPN subnet
3. Appending the peer to the server configuration
4. Writing a client `.conf` file to `/etc/wireguard/clients`
5. Printing a QR code for easy mobile onboarding

## Requirements

- Ubuntu or Debian-based Linux server
- Root or `sudo` access
- A public IP or DNS name for your server
- UDP port `51820` open to the server
- Temporary TCP port `3000` open for the AdGuard Home setup UI

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/wireguard-adguard-vpn-kit.git
cd wireguard-adguard-vpn-kit
```

### 2. Run the server setup

```bash
sudo bash scripts/setup-server.sh
```

### 3. Finish AdGuard Home setup

Open:

```text
http://YOUR_SERVER_IP:3000
```

In the AdGuard Home setup wizard:

- Bind DNS to `0.0.0.0:53`
- Keep default blocklists enabled
- Use `10.66.66.1` as the VPN DNS endpoint

### 4. Add clients

```bash
sudo bash scripts/add-client.sh iphone
sudo bash scripts/add-client.sh laptop
sudo bash scripts/add-client.sh tablet
```

Client configs will be written to:

```text
/etc/wireguard/clients/
```

## Example Client Workflow

After creating a client, import the generated `.conf` file into the WireGuard app.

For mobile devices, the script prints a QR code directly in the terminal.

## Configuration Defaults

| Setting | Value |
|---|---|
| WireGuard interface | `wg0` |
| WireGuard port | `51820/UDP` |
| VPN subnet | `10.66.66.0/24` |
| Server VPN address | `10.66.66.1/24` |
| VPN DNS | `10.66.66.1` |
| AdGuard data dir | `/opt/adguardhome/work` |
| AdGuard config dir | `/opt/adguardhome/conf` |

## Security Notes

- Keep port `53` closed to the public internet unless you intentionally want public DNS.
- Restrict SSH access before exposing this server publicly.
- Back up `/etc/wireguard` and `/opt/adguardhome/conf` securely.
- Rotate keys if a client device is lost.
- Remove old peers from `wg0.conf` when devices are retired.

More detail is in [`docs/SECURITY-NOTES.md`](docs/SECURITY-NOTES.md).

## Improvements Made In This Repo Version

Compared with the uploaded files, this repo version:

- Fixes the recursive self-call at the end of `setup-server.sh`
- Replaces the placeholder `add-client.sh` with a working implementation
- Adds input validation and clearer error messages
- Organizes files for GitHub
- Adds basic CI with ShellCheck

## Suggested GitHub Repo Name

**wireguard-adguard-vpn-kit**

## Suggested GitHub Description

**Deploy a WireGuard VPN server with AdGuard Home DNS filtering and generate client configs with QR codes using simple Bash scripts.**

## License

No license file was added automatically. Choose one deliberately before publishing. For a simple public repo, many people use **MIT**.
