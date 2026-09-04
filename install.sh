#!/bin/bash

set -e

echo "[*] Installing dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S git wget jre21-openjdk --noconfirm
sudo archlinux-java set java-21-openjdk

echo "[*] Creating directory..."
sudo mkdir -p /opt/burpsuite
sudo chown $USER:$USER /opt/burpsuite

echo "[*] Cloning repo..."
git clone https://github.com/xiv3r/Burpsuite-Professional.git /opt/burpsuite
cd /opt/burpsuite

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

echo "[*] Detecting display backend..."
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_BACKEND="wayland"
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export XDG_SESSION_TYPE=wayland
    unset DISPLAY
elif [ -n "$DISPLAY" ]; then
    DISPLAY_BACKEND="x11"
    export DISPLAY=:0
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
else
    DISPLAY_BACKEND="x11"
    echo "[!] No display detected. Assuming X11."
    export DISPLAY=:0
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
fi
echo "[*] Display backend: $DISPLAY_BACKEND"

echo "[*] Building launcher script..."
cat > burpsuitepro << 'EOF'
#!/bin/bash
cd /opt/burpsuite

# Detect display backend
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export XDG_SESSION_TYPE=wayland
    unset DISPLAY
else
    export DISPLAY=:0
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
fi

java -Djava.awt.headless=false \
     -Dawt.toolkit=sun.awt.X11.XToolkit \
     -Dsun.java2d.xrender=true \
     --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
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

# Build exec command based on detected backend
if [ "$DISPLAY_BACKEND" = "wayland" ]; then
    EXEC_PREFIX="env GDK_BACKEND=wayland QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland"
else
    EXEC_PREFIX="env DISPLAY=:0 GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb"
fi

cat > ~/.local/share/applications/burpsuitepro.desktop << EOF
[Desktop Entry]
Type=Application
Name=Burp Suite Professional
Comment=Web Security Testing Tool
Exec=$EXEC_PREFIX /usr/lib/jvm/java-21-openjdk/bin/java -Djava.awt.headless=false -Dawt.toolkit=sun.awt.X11.XToolkit -Dsun.java2d.xrender=true --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:/opt/burpsuite/loader.jar -noverify -jar /opt/burpsuite/burpsuite_pro_v2026.jar
Icon=/home/$USERNAME/.local/share/icons/burpsuite.ico
Terminal=false
Categories=Development;Security;
EOF

chmod +x ~/.local/share/applications/burpsuitepro.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "[*] Launching Burp Suite Pro..."
./burpsuitepro &

echo "[*] Done. Loader PID: $LOADER_PID"
echo "[*] Display backend: $DISPLAY_BACKEND"
echo "[*] Burp Suite installed to /opt/burpsuite"
