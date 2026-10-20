#!/bin/bash
set -e

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo "~$REAL_USER")
DESKTOP_DIR="$REAL_HOME/Desktop"

mkdir -p "$DESKTOP_DIR"
mkdir -p "$REAL_HOME/.config/autostart"

sudo apt update && sudo apt install -y zenity > /dev/null 2>&1 || true

cat << 'KIOEOF' > "$REAL_HOME/alarmmonitor/kiosk.desktop"
[Desktop Entry]
Type=Application
Name=Alarmmonitor Kiosk
Exec=chromium-browser --kiosk --noerrdialogs --disable-infobars --check-for-update-interval=31536000 --autoplay-policy=no-user-gesture-required http://localhost:5000
X-GNOME-Autostart-enabled=true
KIOEOF

cat << AKTEOF > "$DESKTOP_DIR/Autostart_Aktivieren.desktop"
[Desktop Entry]
Type=Application
Name=Autostart AKTIVIEREN
Comment=Kiosk-Modus beim Booten einschalten
Exec=bash -c "mkdir -p $REAL_HOME/.config/autostart && cp $REAL_HOME/alarmmonitor/kiosk.desktop $REAL_HOME/.config/autostart/kiosk.desktop && zenity --info --title='Alarmmonitor' --text='Autostart für den nächsten Boot wurde AKTIVIERT!' --timeout=3 2>/dev/null"
Icon=emblem-default
Terminal=false
AKTEOF

cat << DEAKTEOF > "$DESKTOP_DIR/Autostart_Deaktivieren.desktop"
[Desktop Entry]
Type=Application
Name=Autostart DEAKTIVIEREN
Comment=Kiosk-Modus beim Booten ausschalten
Exec=bash -c "rm -f $REAL_HOME/.config/autostart/kiosk.desktop && zenity --info --title='Alarmmonitor' --text='Autostart für den nächsten Boot wurde DEAKTIVIERT!' --timeout=3 2>/dev/null"
Icon=process-stop
Terminal=false
DEAKTEOF

chmod +x "$DESKTOP_DIR/Autostart_Aktivieren.desktop"
chmod +x "$DESKTOP_DIR/Autostart_Deaktivieren.desktop"
chown -R $REAL_USER:$REAL_USER "$DESKTOP_DIR"

echo "Shortcuts wurden erstellt!"
