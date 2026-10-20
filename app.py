import os
import json
import time
import threading
from datetime import datetime
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

AUTO_RESET_MINUTES = 30
DATA_FILE = os.path.join(os.path.dirname(__file__), 'alarms.json')
SETTINGS_FILE = os.path.join(os.path.dirname(__file__), 'settings.json')

file_lock = threading.Lock()

DEFAULT_SETTINGS = {
    "fahrzeuge": ["LF 10", "MTW", "TLF 3000", "ELW 1", "DLK 23/12"],
    "stichwoerter": ["B1 - Containerbrand", "B2 - Gebäudebrand", "THL1 - Ölspur", "THL2 - VU Person klemmt", "BMA - Auslösung"],
    "ziele": ["Übungsplatz Hof", "Hauptstraße / Parkplatz", "Musterfirma, Hallenstr. 4", "Musterweg 12", "Gerätehaus"],
    "presets": [
        {"name": "Containerbrand", "stichwort": "B1 - Containerbrand", "adresse": "Übungsplatz Hof", "fahrzeuge": "LF 10", "hinweis": "Starke Rauchentwicklung"},
        {"name": "Ölspur klein", "stichwort": "THL1 - Ölspur", "adresse": "Hauptstraße / Parkplatz", "fahrzeuge": "MTW", "hinweis": "Ölbinder erforderlich"},
        {"name": "Fehlauslösung BMA", "stichwort": "BMA - Auslösung", "adresse": "Musterfirma, Hallenstr. 4", "fahrzeuge": "LF 10", "hinweis": "Rauchmelder Linie 12"}
    ]
}

def load_data():
    with file_lock:
        if os.path.exists(DATA_FILE):
            try:
                with open(DATA_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Fehler beim Laden der JSON-Datei: {e}")
        return {"active_alarms": [], "alarm_history": []}

def save_data(data):
    with file_lock:
        try:
            with open(DATA_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Fehler beim Speichern der JSON-Datei: {e}")

def load_settings():
    with file_lock:
        if os.path.exists(SETTINGS_FILE):
            try:
                with open(SETTINGS_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Fehler beim Laden der Settings-Datei: {e}")
        return DEFAULT_SETTINGS.copy()

def save_settings(data):
    with file_lock:
        try:
            with open(SETTINGS_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Fehler beim Speichern der Settings-Datei: {e}")

@app.route('/')
def display():
    return render_template('display.html')

@app.route('/admin')
def admin():
    return render_template('admin.html')

# === API ALARME ===
@app.route('/api/alarm', methods=['GET', 'POST'])
def handle_alarm():
    data_store = load_data()
    active_alarms = data_store.get("active_alarms", [])
    alarm_history = data_store.get("alarm_history", [])
    now_ts = time.time()
    
    if request.method == 'POST':
        req_data = request.json or {}
        new_alarm = {
            'id': int(now_ts * 1000),
            'stichwort': str(req_data.get('stichwort', 'EINSATZ')),
            'adresse': str(req_data.get('adresse', '')),
            'fahrzeuge': str(req_data.get('fahrzeuge', '')),
            'hinweis': str(req_data.get('hinweis', '')),
            'timestamp': now_ts,
            'timestr': datetime.now().strftime("%H:%M:%S")
        }
        active_alarms.insert(0, new_alarm)
        alarm_history.insert(0, new_alarm)
        
        save_data({"active_alarms": active_alarms, "alarm_history": alarm_history})
        return jsonify({"status": "success", "alarms": active_alarms})
    
    cleaned_active = [
        a for a in active_alarms 
        if (now_ts - a['timestamp']) < (AUTO_RESET_MINUTES * 60)
    ]
    
    if len(cleaned_active) != len(active_alarms):
        save_data({"active_alarms": cleaned_active, "alarm_history": alarm_history})
        
    return jsonify(cleaned_active)

@app.route('/api/alarm/reset', methods=['POST'])
def reset_alarm():
    data_store = load_data()
    req_data = request.json or {}
    alarm_id = req_data.get('id')
    
    if alarm_id:
        active_alarms = [a for a in data_store.get("active_alarms", []) if a['id'] != alarm_id]
    else:
        active_alarms = []
        
    data_store["active_alarms"] = active_alarms
    save_data(data_store)
    return jsonify({"status": "reset", "active": active_alarms})

@app.route('/api/history', methods=['GET', 'DELETE'])
def handle_history():
    data_store = load_data()
    if request.method == 'DELETE':
        data_store["alarm_history"] = []
        save_data(data_store)
        return jsonify({"status": "cleared", "history": []})
        
    return jsonify(data_store.get("alarm_history", []))

# === API EINSTELLUNGEN & PRESETS ===
@app.route('/api/settings', methods=['GET', 'POST'])
def handle_settings():
    if request.method == 'POST':
        data = request.json or {}
        save_settings(data)
        return jsonify({"status": "success", "settings": data})
    return jsonify(load_settings())

@app.route('/api/settings/reset', methods=['POST'])
def reset_settings():
    req_data = request.json or {}
    category = req_data.get('category')
    current_settings = load_settings()
    
    if category in DEFAULT_SETTINGS:
        current_settings[category] = DEFAULT_SETTINGS[category].copy()
    elif category == 'all':
        current_settings = DEFAULT_SETTINGS.copy()
        
    save_settings(current_settings)
    return jsonify({"status": "reset", "settings": current_settings})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
