#!/bin/bash

set -e

echo "[*] Installing dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S git wget jre21-openjdk --noconfirm
sudo archlinux-java set java-21-openjdk

echo "[*] Cloning repo..."
git clone https://github.com/xiv3r/Burpsuite-Professional.git
cd Burpsuite-Professional

echo "[*] Downloading Burp Suite Pro..."
version=2026
wget -q --show-progress -O burpsuite_pro_v$version.jar \
    https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v$version.jar

if [ ! -f loader.jar ]; then
    echo "[!] loader.jar missing. Ensure it's in the repo or download it."
    exit 1
fi

echo "[*] Starting loader..."
java -jar loader.jar &
LOADER_PID=$!
sleep 2

echo "[*] Building launcher script..."
cat > burpsuitepro << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:./loader.jar \
     -noverify \
     -jar ./burpsuite_pro_v2026.jar
EOF

chmod +x burpsuitepro
sudo cp burpsuitepro /usr/local/bin/burpsuitepro

echo "[*] Downloading icon..."
mkdir -p ~/.local/share/icons
wget -q -O ~/.local/share/icons/burpsuite.ico https://raw.githubusercontent.com/xiv3r/Burpsuite-Professional/main/burpsuite.ico 2>/dev/null || \
wget -q -O ~/.local/share/icons/burpsuite.ico https://portswigger.net/favicon.ico 2>/dev/null || \
echo "[!] No icon downloaded."

echo "[*] Creating .desktop file..."
mkdir -p ~/.local/share/applications
USERNAME=$(whoami)
cat > ~/.local/share/applications/burpsuitepro.desktop << EOF
[Desktop Entry]
Type=Application
Name=Burp Suite Professional
Comment=Web Security Testing Tool
Exec=/usr/lib/jvm/java-21-openjdk/bin/java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:/home/$USERNAME/Burpsuite-Professional/loader.jar -noverify -jar /home/$USERNAME/Burpsuite-Professional/burpsuite_pro_v2026.jar
Icon=/home/$USERNAME/.local/share/icons/burpsuite.ico
Terminal=false
Categories=Development;Security;
EOF

chmod +x ~/.local/share/applications/burpsuitepro.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "[*] Launching Burp Suite Pro..."
./burpsuitepro &

echo "[*] Done. Loader PID: $LOADER_PID"
