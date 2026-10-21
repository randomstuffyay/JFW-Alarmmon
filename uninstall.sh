#!/bin/bash
set -e

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo "~$REAL_USER")
INSTALL_DIR="$REAL_HOME/JFW-Alarmmon"

echo "=== JFW-Alarmmon Deinstallation ==="

if [ "$EUID" -ne 0 ]; then
  echo "Bitte führe dieses Skript mit sudo aus: sudo ./uninstall.sh"
  exit 1
fi

echo "[1/4] Stoppe und deaktiviere den systemd Service..."
if systemctl list-unit-files | grep -q "alarmmonitor.service"; then
    systemctl stop alarmmonitor.service || true
    systemctl disable alarmmonitor.service || true
    rm -f /etc/systemd/system/alarmmonitor.service
    systemctl daemon-reload
    systemctl reset-failed
    echo " -> Service erfolgreich entfernt."
else
    echo " -> Kein aktiver Service gefunden."
fi

echo "[2/4] Entferne Autostart-Verknüpfungen und Desktop-Icons..."
rm -f "$REAL_HOME/.config/autostart/kiosk.desktop"
rm -f "$REAL_HOME/Desktop/Autostart_Aktivieren.desktop"
rm -f "$REAL_HOME/Desktop/Autostart_Deaktivieren.desktop"

echo "[3/4] Bereinige Installationsverzeichnis..."
if [ -d "$INSTALL_DIR" ]; then
    read -p "Möchtest du auch die Konfiguration und Datenbank (settings.json, alarms.json) unwiderruflich löschen? (j/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo " -> Verzeichnis $INSTALL_DIR komplett gelöscht."
    else
        echo " -> Verzeichnis $INSTALL_DIR wurde behalten (Enthält noch Daten/Settings)."
    fi
else
    echo " -> Verzeichnis $INSTALL_DIR existiert nicht."
fi

echo "=== Deinstallation abgeschlossen! ==="
