#!/bin/bash

echo "[*] Killing Burp Suite processes..."
pkill -f "burpsuite_pro_v2026.jar" 2>/dev/null
pkill -f "loader.jar" 2>/dev/null

echo "[*] Removing desktop entry..."
rm -f ~/.local/share/applications/burpsuitepro.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "[*] Removing launcher script..."
sudo rm -f /usr/local/bin/burpsuitepro

echo "[*] Removing Burp Suite directory..."
rm -rf ~/Burpsuite-Professional

echo "[*] Removing Java packages (optional)..."
read -p "Remove JRE 21 and git/wget? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -Rs jre21-openjdk git wget --noconfirm
fi

echo "[*] Done. Burp Suite removed."
