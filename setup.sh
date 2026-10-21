#!/bin/bash
set -e

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo "~$REAL_USER")
INSTALL_DIR="$REAL_HOME/JFW-Alarmmon"

# Parameter-Parsing (--keep-config oder --overwrite-config)
OVERWRITE_CONFIG=false
KEEP_CONFIG=false

for arg in "$@"; do
    case $arg in
        --keep-config)
            KEEP_CONFIG=true
            ;;
        --overwrite-config)
            OVERWRITE_CONFIG=true
            ;;
    esac
done

echo "[1/6] Aktualisiere Paketlisten und installiere Software..."
sudo apt update
sudo apt install -y python3 python3-flask chromium-browser unclutter ffmpeg lightdm zenity libglib2.0-bin

echo "[2/6] Richte automatischen Benutzer-Login (Autologin) ein..."
sudo raspi-config nonint do_boot_behaviour B4

echo "[3/6] Erstelle Ordnerstruktur..."
mkdir -p "$INSTALL_DIR/static"
mkdir -p "$INSTALL_DIR/templates"
mkdir -p "$REAL_HOME/.config/autostart"

echo "[4/6] Überprüfe Konfigurationsdateien (settings.json / alarms.json)..."
if [ -f "$INSTALL_DIR/settings.json" ] || [ -f "$INSTALL_DIR/alarms.json" ]; then
    if [ "$KEEP_CONFIG" = true ]; then
        echo " -> Bestehende Konfigurationsdateien werden durch Parameter --keep-config geschützt."
    elif [ "$OVERWRITE_CONFIG" = true ]; then
        echo " -> Bestehende Konfigurationsdateien werden durch Parameter --overwrite-config überschrieben."
        rm -f "$INSTALL_DIR/settings.json" "$INSTALL_DIR/alarms.json"
    else
        echo
        read -p "Es existieren bereits Konfigurationsdateien (settings.json / alarms.json). Möchtest du diese überschreiben? (j/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            rm -f "$INSTALL_DIR/settings.json" "$INSTALL_DIR/alarms.json"
            echo " -> Bestehende Konfigurationen wurden gelöscht und werden neu erstellt."
        else
            echo " -> Bestehende Konfigurationsdateien werden beibehalten."
        fi
    fi
fi

echo "[5/6] Generiere Standard-Alarmton..."
if [ ! -f "$INSTALL_DIR/static/gong.mp3" ]; then
    ffmpeg -y -f lavfi -i "sine=frequency=880:duration=0.4,afade=t=out:st=0.2:d=0.2" \
    -f lavfi -i "sine=frequency=660:duration=0.8,afade=t=out:st=0.4:d=0.4" \
    -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" \
    "$INSTALL_DIR/static/gong.mp3" > /dev/null 2>&1
fi

echo "[6/6] Richte systemd-Service und Kiosk-Autostart ein..."
cat <<SERVICEEOF | sudo tee /etc/systemd/system/alarmmonitor.service > /dev/null
[Unit]
Description=Feuerwehr Alarmmonitor Webserver (JFW-Alarmmon)
After=network.target

[Service]
User=$REAL_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable alarmmonitor.service
sudo systemctl restart alarmmonitor.service

chmod +x "$INSTALL_DIR/create_shortcuts.sh" 2>/dev/null || true
bash "$INSTALL_DIR/create_shortcuts.sh"

chown -R $REAL_USER:$REAL_USER "$INSTALL_DIR"

echo "Installation von JFW-Alarmmon vollständig abgeschlossen!"
