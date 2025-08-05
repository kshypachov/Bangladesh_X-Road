# Aptly-based Debian Repository for NIIS X-Road

This repository contains scripts for deploying a Debian package repository infrastructure based on [Aptly](https://www.aptly.info/), including mirroring the official NIIS X-Road repository into a local Aptly-managed repository.

## Contents

- `install.sh` — installs Aptly and sets up GPG signing keys.
- `install_with_nginx.sh` — installs both Aptly and NGINX. Aptly is used for package signing and repository management, while NGINX serves the repository files over HTTP(S).
- `mirror_x_road_repo.sh` — clones (mirrors) the official NIIS X-Road repository into the local Aptly repository.

---

## 📦 Installing Aptly

### Script: `install.sh`

Installs Aptly and configures GPG keys required for signing packages in the local repository.

Example usage:

```bash
./install.sh
```

---

## 🌐 Installing Aptly with NGINX

### Script: `install_with_nginx.sh`

Additionally installs and configures NGINX, allowing Aptly to publish repository contents over HTTP(S).

Example usage:

```bash
./install_with_nginx.sh
```

---

## 🔁 Mirroring the X-Road Repository

### Script: `mirror_x_road_repo.sh`

After Aptly (and optionally NGINX) is installed, this script is used to mirror the official [NIIS X-Road](https://artifactory.niis.org/xroad-release-deb) repository into a local Aptly-managed repository.

Before running the script, you can customize its configuration by modifying the variables at the top:

```bash
X_ROAD_REL="noble-current"                      # Target release series (e.g. Ubuntu)
X_ROAD_FORK="main"                              # Repository branch
X_ROAD_REPO="https://artifactory.niis.org/xroad-release-deb"
X_ROAD_REPO_KEY="https://artifactory.niis.org/api/gpg/key/public"
X_ROAD_LOCAL_REPO_NAME="xroad-remote"           # Local mirror name
X_ROAD_LOCAL_SNAP="${X_ROAD_LOCAL_REPO_NAME}-snap"  # Snapshot name
```

Example usage:

```bash
./mirror_x_road_repo.sh
```

---

## 🗝️ Requirements

- Ubuntu/Debian-based system
- `sudo` privileges
- Internet access
- GPG (for signing the repository)
- Optionally: NGINX for publishing

---

## 📄 License

MIT 

---

## 📬 Contact

For questions or suggestions, open an [Issue](https://github.com/kshypachov/Bangladesh_X-Road/issues) or contact the maintainer directly.