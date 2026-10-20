#!/bin/bash
set -e

DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$HOME/.config/autostart"

sudo apt update && sudo apt install -y zenity > /dev/null 2>&1 || true

cat << 'KIOEOF' > "$HOME/alarmmonitor/kiosk.desktop"
[Desktop Entry]
Type=Application
Name=Alarmmonitor Kiosk
Exec=chromium-browser --kiosk --noerrdialogs --disable-infobars --check-for-update-interval=31536000 --autoplay-policy=no-user-gesture-required http://localhost:5000
X-GNOME-Autostart-enabled=true
KIOEOF

cat << 'AKTEOF' > "$DESKTOP_DIR/Autostart_Aktivieren.desktop"
[Desktop Entry]
Type=Application
Name=Autostart AKTIVIEREN
Comment=Kiosk-Modus beim Booten einschalten
Exec=bash -c "mkdir -p $HOME/.config/autostart && cp $HOME/alarmmonitor/kiosk.desktop $HOME/.config/autostart/kiosk.desktop && zenity --info --title='Alarmmonitor' --text='Autostart für den nächsten Boot wurde AKTIVIERT!' --timeout=3 2>/dev/null"
Icon=emblem-default
Terminal=false
AKTEOF

cat << 'DEAKTEOF' > "$DESKTOP_DIR/Autostart_Deaktivieren.desktop"
[Desktop Entry]
Type=Application
Name=Autostart DEAKTIVIEREN
Comment=Kiosk-Modus beim Booten ausschalten
Exec=bash -c "rm -f $HOME/.config/autostart/kiosk.desktop && zenity --info --title='Alarmmonitor' --text='Autostart für den nächsten Boot wurde DEAKTIVIERT!' --timeout=3 2>/dev/null"
Icon=process-stop
Terminal=false
DEAKTEOF

chmod +x "$DESKTOP_DIR/Autostart_Aktivieren.desktop"
chmod +x "$DESKTOP_DIR/Autostart_Deaktivieren.desktop"

echo "Shortcuts wurden erstellt!"
