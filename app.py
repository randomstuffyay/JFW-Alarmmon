import time
from datetime import datetime
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

AUTO_RESET_MINUTES = 30
active_alarms = []
alarm_history = []

PRESETS = [
    {"name": "B1 - Containerbrand", "stichwort": "B1 - Containerbrand", "adresse": "Übungsplatz Hof", "fahrzeuge": "LF 10", "hinweis": "Starke Rauchentwicklung"},
    {"name": "THL1 - Ölspur", "stichwort": "THL1 - Ölspur klein", "adresse": "Hauptstraße / Parkplatz", "fahrzeuge": "MTW", "hinweis": "Ölbinder erforderlich"},
    {"name": "BMA - Fehlauslösung", "stichwort": "BMA - Auslösung", "adresse": "Musterfirma, Hallenstr. 4", "fahrzeuge": "LF 10", "hinweis": "Rauchmelder Linie 12"},
    {"name": "THL - Person in Not", "stichwort": "THL1 - Türöffnung", "adresse": "Musterweg 12", "fahrzeuge": "MTW", "hinweis": "Hilflose Person"}
]

@app.route('/')
def display():
    return render_template('display.html')

@app.route('/admin')
def admin():
    return render_template('admin.html', presets=PRESETS)

@app.route('/api/alarm', methods=['GET', 'POST'])
def handle_alarm():
    global active_alarms, alarm_history
    now_ts = time.time()
    
    if request.method == 'POST':
        data = request.json
        new_alarm = {
            'id': int(now_ts * 1000),
            'stichwort': data.get('stichwort', 'EINSATZ'),
            'adresse': data.get('adresse', ''),
            'fahrzeuge': data.get('fahrzeuge', ''),
            'hinweis': data.get('hinweis', ''),
            'timestamp': now_ts,
            'timestr': datetime.now().strftime("%H:%M:%S")
        }
        active_alarms.insert(0, new_alarm)
        alarm_history.insert(0, new_alarm)
        return jsonify({"status": "success", "alarms": active_alarms})
    
    active_alarms = [
        a for a in active_alarms 
        if (now_ts - a['timestamp']) < (AUTO_RESET_MINUTES * 60)
    ]
    return jsonify(active_alarms)

@app.route('/api/alarm/reset', methods=['POST'])
def reset_alarm():
    global active_alarms
    data = request.json or {}
    alarm_id = data.get('id')
    
    if alarm_id:
        active_alarms = [a for a in active_alarms if a['id'] != alarm_id]
    else:
        active_alarms = []
        
    return jsonify({"status": "reset", "active": active_alarms})

@app.route('/api/history', methods=['GET'])
def get_history():
    return jsonify(alarm_history)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
