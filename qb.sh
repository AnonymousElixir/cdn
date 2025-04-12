#!/bin/bash
echo "Updating APT package list..."
sudo apt update
echo "Installing Snap..."
sudo apt install snapd -y
echo "Installing Discord..."
sudo snap install discord
echo "Installing Sober (via Flatpak)..."
flatpak install flathub sober -y
echo "Finished Install Of Sober & Discord"
sleep 2
DISCORD_DESKTOP="$HOME/Desktop/Discord.desktop"
SOBER_DESKTOP="$HOME/Desktop/Sober.desktop"
cat > "$DISCORD_DESKTOP" <<EOL
[Desktop Entry]
Name=Discord
Exec=snap run discord
Icon=/snap/discord/current/meta/gui/icon.png
Type=Application
Terminal=false
EOL
cat > "$SOBER_DESKTOP" <<EOL
[Desktop Entry]
Name=Sober
Exec=flatpak run sober
Icon=sober
Type=Application
Terminal=false
EOL
chmod +x "$DISCORD_DESKTOP" "$SOBER_DESKTOP"
echo "Launchers created on Desktop!"
