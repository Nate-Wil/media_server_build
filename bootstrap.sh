#!/usr/bin/env bash
set -e

echo "=== Media Server Bootstrap (Debian 13) ==="

# Ensure running as non-root with sudo
if [[ "$EUID" -eq 0 ]]; then
  echo "Please run as a normal user with sudo privileges."
  exit 1
fi

# ----------------------------------------
# System update
# ----------------------------------------
echo "Updating system..."
sudo apt update && sudo apt full-upgrade -y

# ----------------------------------------
# Base packages
# ----------------------------------------
echo "Installing base packages..."
sudo apt install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  sudo \
  rsync \
  openssh-server \
  htop \
  nano \
  vim \
  fastfetch \
  tmux \
  unzip

# ----------------------------------------
# Docker install
# ----------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."

  sudo apt remove -y docker docker-engine docker.io containerd runc || true

  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  trixie stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update

  sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker already installed — skipping"
fi

# ----------------------------------------
# Add user to docker group
# ----------------------------------------
if ! groups "$USER" | grep -q docker; then
  echo "Adding user to docker group..."
  sudo usermod -aG docker "$USER"
  echo "You must log out and back in for docker group to apply."
fi

# ----------------------------------------
# Portainer
# ----------------------------------------
if ! docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
  echo "Deploying Portainer..."

  docker volume create portainer_data || true

  docker run -d \
    --name portainer \
    --restart=always \
    -p 8000:8000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
else
  echo "Portainer already running — skipping"
fi

# ----------------------------------------
# Media directories
# ----------------------------------------
echo "Creating media directories..."
sudo mkdir -p /media/movies /media/tv
sudo chown -R "$USER":"$USER" /media

# ----------------------------------------
# Done
# ----------------------------------------
echo ""
echo "Bootstrap complete."
echo "Next steps:"
echo "  - Log out and back in (or reboot)"
echo "  - Visit https://<server-ip>:9443 for Portainer"
echo "  - Add Plex/Jellyfin via Compose"
echo "  - Configure nightly rsync from NAS"
