#!/bin/bash
set -e

# In das Verzeichnis wechseln, in dem das Skript liegt
CDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CDIR"

echo "=== JFW-Alarmmon Sound-Generator ==="
echo "Starte Generierung der Alarmsounds via Python..."

if [ ! -f "generate_sounds.py" ]; then
    echo "Fehler: generate_sounds.py wurde nicht gefunden!"
    exit 1
fi

python3 generate_sounds.py

echo "=== Sound-Generierung erfolgreich abgeschlossen! ==="
