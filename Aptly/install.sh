#!/bin/bash

set -e

# === 1. Installing aptly ===
echo "[1/5] Installing aptly..."
sudo apt update
sudo apt install -y gnupg curl

# Add aptly repository
curl -fsSL https://www.aptly.info/pubkey.txt | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg
echo "deb http://repo.aptly.info/ squeeze main" | sudo tee /etc/apt/sources.list.d/aptly.list

sudo apt update
sudo apt install -y aptly

# === 2. Generate GPG key (if not present) ===
echo "[2/5] Checking GPG key..."

GPG_EMAIL="repo@example.com"
GPG_NAME="APT Repo Signing Key"
GPG_KEY_ID=$(gpg --list-keys --with-colons "$GPG_EMAIL" 2>/dev/null | awk -F: '/^pub/ { print $5 }')

if [ -z "$GPG_KEY_ID" ]; then
  echo "[!] Key not found, generating..."
  cat > gpg_batch <<EOF
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
  gpg --batch --gen-key gpg_batch
  rm -f gpg_batch
  GPG_KEY_ID=$(gpg --list-keys --with-colons "$GPG_EMAIL" | awk -F: '/^pub/ { print $5 }')
fi

echo "[✓] Using GPG key: $GPG_KEY_ID"

# === 3. Configure aptly.conf ===
echo "[3/5] Configuring ~/.aptly.conf..."

cat > ~/.aptly.conf <<EOF
{
  "rootDir": "$HOME/.aptly",
  "downloadConcurrency": 4,
  "architectures": ["amd64"],
  "dependencyFollowSuggests": false,
  "dependencyFollowRecommends": false,
  "dependencyFollowAllVariants": false,
  "dependencyFollowSource": false,
  "gpgDisableSign": false,
  "gpgDisableVerify": false,
  "gpgProvider": "gpg",
  "gpgKey": "$GPG_KEY_ID"
}
EOF

# === 4. Prepare directories ===
echo "[4/5] Creating directories..."
mkdir -p ~/.aptly/public

# === 5. Final output ===
echo "[5/5] Done."
echo "Aptly has been installed and configured. GPG key: $GPG_KEY_ID"
echo "To publish a repository, use commands like:"
echo "  aptly repo create myrepo"
echo "  aptly repo add myrepo ./path/to/packages"
echo "  aptly publish repo -architectures=amd64 myrepo"