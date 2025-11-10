#!/bin/bash

#================================================================
# MukenVault Pre-Check - One-Line Installer
#================================================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   MukenVault Pre-Installation Checker                       ║
║   Installation Script                                       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Root権限チェック
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   echo "Please use: sudo $0"
   exit 1
fi

echo -e "${GREEN}✅ Root access confirmed${NC}"
echo ""

# 一時ディレクトリ作成
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📦 Downloading MukenVault Pre-Check script..."

# GitHubからダウンロード
REPO_URL="https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main"

if command -v curl &> /dev/null; then
    curl -fsSL "${REPO_URL}/mukenvault_pre_check.sh" -o mukenvault_pre_check.sh
elif command -v wget &> /dev/null; then
    wget -q "${REPO_URL}/mukenvault_pre_check.sh" -O mukenvault_pre_check.sh
else
    echo -e "${RED}Error: Neither curl nor wget found${NC}"
    exit 1
fi

if [ ! -f mukenvault_pre_check.sh ]; then
    echo -e "${RED}Error: Failed to download script${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Download complete${NC}"
echo ""

chmod +x mukenvault_pre_check.sh

echo "🚀 Starting MukenVault Pre-Check..."
echo ""

./mukenvault_pre_check.sh

cd /
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  MukenVault Pre-Check completed successfully!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
