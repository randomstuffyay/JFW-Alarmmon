import os
import subprocess

static_dir = os.path.join(os.path.dirname(__file__), 'static')
os.makedirs(static_dir, exist_ok=True)

print("Generiere doppelte 5-Ton-Folge...")
finton_path = os.path.join(static_dir, 'finton_doppelt.mp3')
f1, f2, f3, f4, f5 = 1100, 1400, 1700, 2000, 2400
tone_filter = (
    f"sine=f={f1}:d=0.07,fade=t=out:st=0.05:d=0.02[t1];"
    f"sine=f={f2}:d=0.07,fade=t=out:st=0.05:d=0.02[t2];"
    f"sine=f={f3}:d=0.07,fade=t=out:st=0.05:d=0.02[t3];"
    f"sine=f={f4}:d=0.07,fade=t=out:st=0.05:d=0.02[t4];"
    f"sine=f={f5}:d=0.15,fade=t=out:st=0.1:d=0.05[t5];"
    f"[t1][t2][t3][t4][t5]concat=n=5:v=0:a=1[round1];"
    f"[round1]apad=pad_dur=0.2[r1_pause];"
    f"[r1_pause][round1]concat=n=2:v=0:a=1[out]"
)

subprocess.run([
    'ffmpeg', '-y', '-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono',
    '-filter_complex', tone_filter, '-map', '[out]', finton_path
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Generiere echten Gong...")
gong_path = os.path.join(static_dir, 'gong_echt.mp3')
gong_filter = (
    "sine=frequency=523.25:duration=1.8,afade=t=out:st=0.2:d=1.6[g1];"
    "sine=frequency=659.25:duration=1.8,afade=t=out:st=0.2:d=1.6[g2];"
    "sine=frequency=783.99:duration=2.2,afade=t=out:st=0.3:d=1.9[g3];"
    "[g1][g2][g3]amix=inputs=3:duration=longest[out]"
)

subprocess.run([
    'ffmpeg', '-y', '-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono',
    '-filter_complex', gong_filter, '-map', '[out]', gong_path
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Fertig! Alle Sounds wurden erfolgreich im Ordner static/ erstellt.")
