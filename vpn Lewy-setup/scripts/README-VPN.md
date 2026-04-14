# Personal VPN Server

## Overview

This project sets up a personal VPN server using **WireGuard** for secure remote access and **AdGuard Home** for private DNS filtering.

The goal is simple:

• Connect phones, laptops, and tablets to a private VPN
• Route device traffic securely through your own server
• Use your own DNS endpoint instead of public resolvers
• Block ads, trackers, and unwanted domains with AdGuard Home

## Features

• WireGuard VPN server setup
• Private subnet for VPN clients
• IP forwarding and NAT configuration
• Docker-based AdGuard Home deployment
• Local DNS endpoint for connected VPN devices
• Client profile generation for multiple devices
• QR code support for easy mobile setup

## Stack

• WireGuard
• AdGuard Home
• Docker
• Bash
• iptables

## How It Works

The server script prepares a Linux host to act as a VPN gateway.

It performs the following tasks:

1. Installs WireGuard, Docker, curl, qrencode, and firewall persistence tools
2. Enables IPv4 and IPv6 forwarding
3. Creates the WireGuard server configuration
4. Applies NAT rules so VPN clients can reach the internet through the server
5. Starts the WireGuard interface
6. Deploys AdGuard Home in Docker
7. Uses the server as the DNS resolver for VPN clients

Client devices receive their own WireGuard configuration and connect through the VPN tunnel. Once connected, their DNS requests can be filtered through AdGuard Home.

## Typical Use Case

This setup is useful when you want to:

• Secure your traffic on public Wi‑Fi
• Access your home or cloud network remotely
• Keep DNS queries under your control
• Reduce ads and tracking across connected devices
• Maintain a lightweight self-hosted VPN solution

## Server Notes

Default values used by the setup:

• WireGuard interface: `wg0`
• VPN port: `51820/UDP`
• VPN subnet: `10.66.66.0/24`
• Server VPN address: `10.66.66.1`
• DNS for clients: `10.66.66.1`
• AdGuard Home setup UI: `http://YOUR_SERVER_IP:3000`

## Firewall Requirements

You should allow:

• `UDP 51820` for WireGuard
• `TCP 3000` temporarily for AdGuard Home initial setup

You should avoid exposing DNS publicly unless that is intentional.

## Example Devices

This VPN can be used for:

• iPhone
• Laptop
• Tablet

Each device should have its own client config and key pair.

## Security Notes

• Keep private keys secret
• Store client config files securely
• Remove unused clients from the server config
• Limit public firewall exposure to only the ports you need
• Update the server regularly
• Protect the AdGuard admin interface with a strong password

## Project Layout

A typical layout for this VPN project is:

```text
.
├── README.md
├── scripts/
│   ├── setup-server.sh
│   └── add-client.sh
└── docs/
    └── SECURITY-NOTES.md
```

## Setup Summary

### 1. Provision the server
Run the server setup script as root on a supported Linux server.

### 2. Complete AdGuard Home setup
Open the setup interface in a browser and finish the initial configuration.

### 3. Create client profiles
Generate a client configuration for each device you want to connect.

### 4. Import the client config
Import the generated profile into the WireGuard app on the device.

### 5. Connect and test
Verify that traffic routes through the VPN and DNS resolves through the server.

## Purpose

This project is designed as a practical self-hosted VPN and filtered DNS setup for personal use, remote access, privacy, and device management.
