#!/usr/bin/env bash
set -euo pipefail

export HOME="/home/exedev"
export USER="exedev"

echo "=== [1/4] Installing system build toolchain ==="
# T3 Code server uses node-pty on Linux, which requires compilation dependencies
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl git make g++ python3 socat jq

echo "=== [2/4] Installing Official T3 Code ==="
# Install official t3 CLI from t3.codes (places binary in ~/.local/bin/t3)
curl -fsSL https://t3.codes/install.sh | bash

# Ensure binary is globally accessible
sudo ln -sf "$HOME/.local/bin/t3" /usr/local/bin/t3

echo "=== [3/4] Pre-configuring T3 Code for Antigravity ==="
# Pre-seed the configuration directory so Antigravity is enabled on boot
CONFIG_DIR="$HOME/.config/t3code"
mkdir -p "$CONFIG_DIR"

# Write default settings.json enabling Antigravity and setting it as default
cat << 'EOF' > "$CONFIG_DIR/settings.json"
{
  "general": {
    "defaultProvider": "antigravity"
  },
  "providers": {
    "antigravity": {
      "enabled": true
    },
    "claude": {
      "enabled": false
    },
    "codex": {
      "enabled": false
    }
  }
}
EOF
chown -R exedev:exedev "$HOME/.config"

echo "=== [4/4] Setting up T3 Code Service & Port 8000 Ingress ==="
# exe.dev automatically exposes port 8000 at https://<vm-name>.exe.xyz.
# T3 Code serves on port 3773 by default. We run t3 serve and port-forward 8000 -> 3773.

sudo tee /etc/systemd/system/t3code.service > /dev/null << 'EOF'
[Unit]
Description=T3 Code Headless Server
After=network.target

[Service]
Type=simple
User=exedev
WorkingDirectory=/home/exedev
Environment="HOME=/home/exedev"
Environment="PATH=/home/exedev/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/t3 serve --port 3773
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Use socat to bridge exe.dev's public HTTPS port (8000) directly into T3 Code (3773)
sudo tee /etc/systemd/system/t3-ingress.service > /dev/null << 'EOF'
[Unit]
Description=Bridge port 8000 to T3 Code port 3773
After=t3code.service

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:8000,fork,reuseaddr TCP:127.0.0.1:3773
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now t3code.service
sudo systemctl enable --now t3-ingress.service

echo "=== Bootstrap Complete ==="
