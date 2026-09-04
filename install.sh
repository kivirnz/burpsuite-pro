#!/bin/bash

set -e

echo "[*] Detecting display backend..."
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_BACKEND="wayland"
    JAVA_PKG="jdk-openjdk-wakefield"
    echo "[*] Wayland detected. Using Wakefield toolkit."
else
    DISPLAY_BACKEND="x11"
    JAVA_PKG="jre21-openjdk"
    echo "[*] X11 detected. Using standard JDK."
fi
echo "[*] Display backend: $DISPLAY_BACKEND"

echo "[*] Installing dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S git wget $JAVA_PKG xorg-xwayland --noconfirm
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

echo "[*] Building launcher script..."
cat > burpsuitepro << 'EOF'
#!/bin/bash
cd /opt/burpsuite

# Detect display backend at runtime
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    # Wayland - use Wakefield
    export _JAVA_OPTIONS="-Dawt.toolkit.name=WLToolkit -Dsun.java2d.vulkan=True"
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export XDG_SESSION_TYPE=wayland
    unset DISPLAY
    
    java -Djava.awt.headless=false \
         --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
         --add-opens=java.base/java.lang=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
         -javaagent:./loader.jar \
         -noverify \
         -jar ./burpsuite_pro_v2026.jar
else
    # X11 - standard JDK
    export DISPLAY=:0
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    
    java -Djava.awt.headless=false \
         -Dawt.toolkit=sun.awt.X11.XToolkit \
         -Dsun.java2d.xrender=true \
         -Dsun.java2d.opengl=true \
         --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
         --add-opens=java.base/java.lang=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
         --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
         -javaagent:./loader.jar \
         -noverify \
         -jar ./burpsuite_pro_v2026.jar
fi
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
Exec=/usr/local/bin/burpsuitepro
Icon=/home/$USERNAME/.local/share/icons/burpsuite.ico
Terminal=false
Categories=Development;Security;
StartupNotify=true
EOF

chmod +x ~/.local/share/applications/burpsuitepro.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "[*] Launching Burp Suite Pro..."
./burpsuitepro &

echo "[*] Done. Loader PID: $LOADER_PID"
echo "[*] Display backend: $DISPLAY_BACKEND"
echo "[*] Java package installed: $JAVA_PKG"
echo "[*] Burp Suite installed to /opt/burpsuite"
