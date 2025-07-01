#!/bin/bash

set -e

# === 1. Установка aptly ===
echo "[1/5] Установка aptly..."
sudo apt update
sudo apt install -y gnupg curl

# Добавим репозиторий aptly
curl -fsSL https://www.aptly.info/pubkey.txt | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg
echo "deb http://repo.aptly.info/ squeeze main" | sudo tee /etc/apt/sources.list.d/aptly.list

sudo apt update
sudo apt install -y aptly

# === 2. Генерация GPG ключа (если его нет) ===
echo "[2/5] Проверка GPG ключа..."

GPG_EMAIL="repo@example.com"
GPG_NAME="APT Repo Signing Key"
GPG_KEY_ID=$(gpg --list-keys --with-colons "$GPG_EMAIL" 2>/dev/null | awk -F: '/^pub/ { print $5 }')

if [ -z "$GPG_KEY_ID" ]; then
  echo "[!] Ключ не найден, создаём..."
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

echo "[✓] Используем GPG ключ: $GPG_KEY_ID"

# === 3. Настройка aptly.conf ===
echo "[3/5] Настройка ~/.aptly.conf..."

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

# === 4. Подготовка директорий ===
echo "[4/5] Создание директорий..."
mkdir -p ~/.aptly/public

# === 5. Вывод финальной информации ===
echo "[5/5] Готово."
echo "Aptly установлен и настроен. GPG-ключ: $GPG_KEY_ID"
echo "Для публикации используйте команды вроде:"
echo "  aptly repo create myrepo"
echo "  aptly repo add myrepo ./path/to/packages"
echo "  aptly publish repo -architectures=amd64 myrepo"