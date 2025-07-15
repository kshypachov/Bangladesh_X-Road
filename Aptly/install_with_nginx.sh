#!/bin/bash

set -e

echo "[1/7] Creating system user aptly..."

# Create a system user without login shell and password
sudo useradd -r -m -d /home/aptly -s /usr/sbin/nologin aptly || true

# But allow root to switch to this user
sudo usermod -s /bin/bash aptly

# Configure sudo access (if needed manually)
# sudo visudo: add a line like:
# Defaults:root !requiretty

echo "[2/7] Installing aptly and GnuPG..."

sudo apt update
sudo apt install -y gnupg2 curl nginx

curl -fsSL https://www.aptly.info/pubkey.txt | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg
echo "deb http://repo.aptly.info/ squeeze main" | sudo tee /etc/apt/sources.list.d/aptly.list
sudo apt update
sudo apt install -y aptly

echo "[3/7] Configuring aptly..."

# Setup directory
sudo mkdir -p /srv/aptly
sudo chown aptly:aptly /srv/aptly

# Create configuration file as aptly user
sudo -u aptly bash -c 'cat > ~/.aptly.conf <<EOF
{
  "rootDir": "/srv/aptly",
  "downloadConcurrency": 4,
  "architectures": ["amd64"],
  "dependencyFollowSuggests": false,
  "dependencyFollowRecommends": false,
  "dependencyFollowAllVariants": false,
  "dependencyFollowSource": false,
  "gpgDisableSign": false,
  "gpgDisableVerify": false,
  "gpgProvider": "gpg",
  "gpgKey": ""
}
EOF'

echo "[4/7] Generating GPG key..."

sudo -u aptly bash -c '
  set -e
  GPG_EMAIL="repo@example.com"
  GPG_NAME="APT Repo Signing Key"
  HOME_DIR="/home/aptly"
  BATCH_FILE="$HOME_DIR/gpg_batch"

  KEY_ID=$(gpg --homedir "$HOME_DIR/.gnupg" --list-keys --with-colons "$GPG_EMAIL" 2>/dev/null | awk -F: "/^pub/ {print \$5}")

  if [ -z "$KEY_ID" ]; then
    cat <<EOF > "$BATCH_FILE"
%no-protection
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: $GPG_NAME
Name-Email: $GPG_EMAIL
Expire-Date: 1y
%commit
EOF

    gpg --homedir "$HOME_DIR/.gnupg" --batch --gen-key "$BATCH_FILE"
    rm -f "$BATCH_FILE"
  fi

  KEY_ID=$(gpg --homedir "$HOME_DIR/.gnupg" --list-keys --with-colons "$GPG_EMAIL" | awk -F: "/^pub/ {print \$5}")

  sed -i "s|\"gpgKey\": \"\"|\"gpgKey\": \"$KEY_ID\"|" "$HOME_DIR/.aptly.conf"

  mkdir -p /srv/aptly/public
  gpg --homedir "$HOME_DIR/.gnupg" --output /srv/aptly/public/aptly.gpg --armor --export "$KEY_ID"
'

echo "[5/7] Configuring nginx..."

sudo tee /etc/nginx/sites-available/aptly >/dev/null <<EOF
server {
    listen 80;
    server_name _;

    root /srv/aptly/public;
    index index.html;

    location / {
        autoindex on;
    }
}
EOF

sudo rm /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/aptly /etc/nginx/sites-enabled/aptly
sudo nginx -t && sudo systemctl reload nginx

echo "[6/7] Setting permissions..."

# nginx should have read-only access to /srv/aptly/public
sudo chmod o+rx /srv/aptly/public
sudo find /srv/aptly/public -type d -exec chmod o+rx {} +
sudo find /srv/aptly/public -type f -exec chmod o+r {} +

echo "[7/7] Done!"

echo "You can now:"
echo "  sudo su - aptly"
echo "  aptly repo create myrepo"
echo "  aptly repo add myrepo /path/to/debs"
echo "  aptly publish repo -architectures=amd64 myrepo"
echo
echo
echo
echo "Repository is available at: http://<IP-address>/"
echo "Public key for client: http://<IP-address>/aptly.gpg"
echo "To add key to ubuntu 24.04+ use:"
echo "  sudo mkdir -p /etc/apt/keyrings"
echo "  curl -fsSL http://<Repo server IP>/aptly.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/aptly.gpg"
echo
echo
echo