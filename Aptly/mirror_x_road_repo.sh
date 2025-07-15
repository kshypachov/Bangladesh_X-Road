#!/bin/bash


X_ROAD_REL="noble-current"
X_ROAD_FORK="main"
X_ROAD_REPO="https://artifactory.niis.org/xroad-release-deb"
X_ROAD_REPO_KEY="https://artifactory.niis.org/api/gpg/key/public"

X_ROAD_LOCAL_REPO_NAME="xroad-remote"

X_ROAD_LOCAL_SNAP="${X_ROAD_LOCAL_REPO_NAME}-snap"

set -e

if [ "$(whoami)" != "aptly" ]; then
  echo "ERROR: This script must be run as the 'aptly' user."
  echo "Use: sudo su - aptly"
  exit 1
fi

echo "[1/6] Initializing keyring..."

mkdir -p ~/.aptly
touch ~/.aptly/trustedkeys.gpg
chmod 600 ~/.aptly/trustedkeys.gpg

echo "[2/6] Importing key from $X_ROAD_REPO_KEY..."
wget -O - $X_ROAD_REPO_KEY | gpg --no-default-keyring --keyring ~/.aptly/trustedkeys.gpg --import

echo "[3/6] Importing from keyserver (fallback)..."
gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keyserver.ubuntu.com --recv-keys FB0D532C10F6EC5B

echo "[4/6] Creating mirror..."
aptly mirror create \
  -architectures="amd64" \
  $X_ROAD_LOCAL_REPO_NAME \
  $X_ROAD_REPO \
  $X_ROAD_REL \
  $X_ROAD_FORK

echo "[5/6] Updating mirror..."
aptly mirror update $X_ROAD_LOCAL_REPO_NAME

echo "[6/6] Creating snapshot and publishing..."
aptly snapshot create $X_ROAD_LOCAL_SNAP from mirror $X_ROAD_LOCAL_REPO_NAME
aptly publish snapshot -architectures=amd64 $X_ROAD_LOCAL_SNAP
echo
echo "Repository is available at: http://<IP-address>/"
echo "Public key for client: http://<IP-address>/aptly.gpg"
echo "To add key to ubuntu 24.04+ use:"
echo "  sudo mkdir -p /etc/apt/keyrings"
echo "  curl -fsSL http://<Repo server IP>/aptly.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/aptly.gpg"
echo
echo
echo "For add repo to ubuntu 24.04+ create file /etc/apt/sources.list.d/${X_ROAD_LOCAL_REPO_NAME}.sources with content:"
echo
echo "Types: deb"
echo "URIs: http://<Repo server IP>/"
echo "Suites: ${X_ROAD_REL}"
echo "Components: ${X_ROAD_FORK}"
echo "Signed-By: /etc/apt/keyrings/aptly.gpg"