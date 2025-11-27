#!/bin/bash

#yes this is generated with claude, I cant be bothered to make it manually

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

error_exit() {
    print_error "$1"
    exit 1
}

[[ $EUID -ne 0 ]] && error_exit "This script must be run as root"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  Chaotic AUR Installation Script     ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

print_step "Retrieving and signing primary key..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || error_exit "Failed to retrieve key"
pacman-key --lsign-key 3056513887B78AEB || error_exit "Failed to sign key"
print_success "Primary key configured"
echo

print_step "Installing chaotic-keyring..."
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || error_exit "Failed to install keyring"
print_success "Keyring installed"
echo

print_step "Installing chaotic-mirrorlist..."
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || error_exit "Failed to install mirrorlist"
print_success "Mirrorlist installed"
echo

print_step "Configuring /etc/pacman.conf..."
if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    print_warning "Repository already configured, skipping"
else
    cat >> /etc/pacman.conf << EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    print_success "Repository added to pacman.conf"
fi
echo

print_step "Updating system and syncing repositories..."
pacman -Syu --noconfirm || error_exit "Failed to update system"
print_success "System updated"
echo

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  Installation Complete! 🚀            ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo
echo "Example usage:"
echo "  pacman -S firedragon"
