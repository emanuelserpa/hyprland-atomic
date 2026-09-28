#!/usr/bin/env python3
import json

from bt_ctl import run_bt

def run(*args):
    try:
        return run_bt(list(args), timeout=5)[1]
    except Exception:
        return ""

show = run("bluetoothctl", "show")
powered = False

for line in show.splitlines():
    line = line.strip()
    if line.startswith("Powered:"):
        powered = line.split(":", 1)[1].strip().lower() == "yes"
        break

print(json.dumps({
    "powered": powered,
    "text": "" if powered else "󰂲",
    "tooltip": "Bluetooth ligado" if powered else "Bluetooth desligado"
}, ensure_ascii=False))
