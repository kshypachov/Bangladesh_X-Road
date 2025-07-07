#!/bin/bash

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

echo "[2/6] Importing key from niis.org..."
wget -O - https://artifactory.niis.org/api/gpg/key/public | gpg --no-default-keyring --keyring ~/.aptly/trustedkeys.gpg --import

echo "[3/6] Importing from keyserver (fallback)..."
gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keyserver.ubuntu.com --recv-keys FB0D532C10F6EC5B

echo "[4/6] Creating mirror..."
aptly mirror create \
  -architectures="amd64" \
  xroad-remote \
  https://artifactory.niis.org/xroad-release-deb \
  jammy-current \
  main

echo "[5/6] Updating mirror..."
aptly mirror update xroad-remote

echo "[6/6] Creating snapshot and publishing..."
aptly snapshot create xroad-snap from mirror xroad-remote
aptly publish snapshot -architectures=amd64 xroad-snap