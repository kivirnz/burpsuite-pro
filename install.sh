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

echo "[*] Launching Burp Suite Pro..."
./burpsuitepro &

echo "[*] Done. Loader PID: $LOADER_PID"
