#!/usr/bin/env python3
"""Battery charge-limit helper (ThinkPad + TLP).

Reads the firmware charge threshold and toggles between the eco limit
(75/80, applied via TLP) and a one-shot full charge (100, "travel mode").

Usage:
    battery-charge-limit.py status        -> JSON envelope with current limit
    battery-charge-limit.py set 80|100    -> apply limit, JSON envelope

JSON contract (same envelope as the other helpers):
    {"ok": bool, "version": 1, "error": str | None, ...}

The `set` path uses `sudo -n` (non-interactive) so the UI gets a clean
error instead of hanging on a password prompt. Passwordless operation
requires a sudoers rule such as:
    emanuel ALL=(ALL) NOPASSWD: /usr/bin/tlp setcharge, /usr/bin/tlp fullcharge BAT0
"""
import glob
import json
import shutil
import subprocess
import sys
from pathlib import Path

VERSION = 1
ECO_START = 75
ECO_STOP = 80
FULL = 100


def detect_battery():
    """First available BAT* supply, preferring BAT0. None when absent."""
    candidates = sorted(glob.glob("/sys/class/power_supply/BAT*"))
    if not candidates:
        return None
    names = [Path(c).name for c in candidates]
    if "BAT0" in names:
        return "BAT0"
    return names[0]


def end_threshold_path(bat):
    return Path(f"/sys/class/power_supply/{bat}/charge_control_end_threshold")


def emit(obj):
    print(json.dumps(obj, ensure_ascii=False))


def run(args, timeout=10.0):
    try:
        cp = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return cp.returncode, (cp.stdout or "").strip(), (cp.stderr or "").strip()
    except Exception as exc:
        return 127, "", str(exc)


def read_int_file(path):
    try:
        return int(Path(path).read_text(encoding="utf-8").strip())
    except Exception:
        return None


def on_ac():
    for candidate in glob.glob("/sys/class/power_supply/AC*/online"):
        value = read_int_file(candidate)
        if value == 1:
            return True
    return False


def current_state():
    bat = detect_battery()
    limit = read_int_file(end_threshold_path(bat)) if bat else None
    if bat is None or limit is None:
        return {
            "ok": False,
            "version": VERSION,
            "available": False,
            "limit": 0,
            "on_ac": on_ac(),
            "error": "Sensor de limite de carga não encontrado.",
        }
    return {
        "ok": True,
        "version": VERSION,
        "available": True,
        "battery": bat,
        "limit": limit,
        "on_ac": on_ac(),
        "error": None,
    }


def apply_limit(limit):
    tlp = shutil.which("tlp")
    if not tlp:
        return False, "tlp não encontrado."
    if not on_ac():
        return False, "Conecte o carregador para alterar o limite de carga."
    sudo = shutil.which("sudo")
    if not sudo:
        return False, "sudo não encontrado."

    bat = detect_battery() or "BAT0"
    if limit == FULL:
        args = [sudo, "-n", tlp, "fullcharge", bat]
    else:
        args = [sudo, "-n", tlp, "setcharge", str(ECO_START), str(ECO_STOP), bat]
    rc, _, err = run(args, timeout=30.0)
    if rc != 0:
        hint = (err or "").strip()
        if "password" in hint.lower() or not hint:
            hint = "Sem permissão sem senha: crie a regra sudoers para tlp setcharge/fullcharge."
        return False, hint
    return True, ""


def main():
    args = sys.argv[1:]

    if not args or args[0] == "status":
        emit(current_state())
        return 0

    if args[0] == "set":
        if len(args) < 2 or args[1] not in ("80", "100"):
            emit({"ok": False, "version": VERSION, "error": "Limite inválido (use 80 ou 100)."})
            return 2
        limit = int(args[1])
        ok, err = apply_limit(limit)
        result = current_state()
        result.update({"ok": ok, "error": err or None})
        emit(result)
        return 0 if ok else 1

    emit({"ok": False, "version": VERSION, "error": "Comando desconhecido."})
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
