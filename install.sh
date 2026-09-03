#!/bin/bash

# Installing Dependencies
echo "Installing Dependencies..."
sudo pacman -Sy
sudo pacman -S git wget jre21-openjdk
sudo archlinux-java set java-21-openjdk
echo "Cloning repo..."
git clone https://github.com/xiv3r/Burpsuite-Professional.git 
cd Burpsuite-Professional
echo "Downloading Burp Suite..."
version=2026
wget -O burpsuite_pro_v$version.jar https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v$version.jar
echo "Starting Key loader.jar..."
(java -jar loader.jar) &
echo "Executing Burpsuite Professional..."
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/burpsuite_pro_v$version.jar &" > burpsuitepro
chmod +x burpsuitepro
cp burpsuitepro /bin/burpsuitepro
(./burpsuitepro)
