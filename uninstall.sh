#!/bin/bash
set -e

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo "~$REAL_USER")

echo "=== JFW-Alarmmon Deinstallation (Systemintegration entfernen) ==="

if [ "$EUID" -ne 0 ]; then
  echo "Bitte führe dieses Skript mit sudo aus: sudo ./uninstall.sh"
  exit 1
fi

echo "[1/3] Stoppe und deaktiviere den systemd Service..."
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

echo "[2/3] Entferne Autostart-Verknüpfungen und Desktop-Icons..."
rm -f "$REAL_HOME/.config/autostart/kiosk.desktop"
rm -f "$REAL_HOME/Desktop/Autostart_Aktivieren.desktop"
rm -f "$REAL_HOME/Desktop/Autostart_Deaktivieren.desktop"
echo " -> Desktop-Verknüpfungen und Autostart entfernt."

echo "[3/3] Quellcode und Konfigurationen (settings.json, alarms.json) wurden geschützt."
echo " -> Der Ordner und deine Einstellungen blieben vollständig erhalten."

echo "=== Deinstallation der Systemintegration erfolgreich abgeschlossen! ==="
