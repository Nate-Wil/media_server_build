#!/bin/bash
set -e

echo "[+] Updating system..."
apt update && apt upgrade -y

echo "[+] Installing basic packages..."
apt install -y git curl wget sudo vim htop net-tools ufw \
               ansible python3 rsync cifs-utils ca-certificates

echo "[+] Creating directory structure..."
mkdir -p /srv/media
mkdir -p /mnt/nas_media

echo "[+] Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "[+] Enabling Docker..."
systemctl enable docker --now

echo "[+] Installing Docker Compose plugin..."
apt install -y docker-compose-plugin

echo "[+] Bootstrap complete. Ready for Ansible deployment."

