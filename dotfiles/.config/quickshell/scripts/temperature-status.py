#!/usr/bin/env python3
"""CPU temperature via hwmon/thermal sysfs. JSON contract for QML."""
import json
import os
import sys
from pathlib import Path

sys.dont_write_bytecode = True

HWMON_BASE = Path(os.environ.get("QSTEMP_HWMON", "/sys/class/hwmon"))
THERMAL_BASE = Path(os.environ.get("QSTEMP_THERMAL", "/sys/class/thermal"))
THERMAL_TYPES = {"x86_pkg_temp", "cpu-thermal", "cpu_thermal", "soc_thermal"}


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _millis_to_celsius(raw: str) -> float | None:
    try:
        n = float(raw)
    except (TypeError, ValueError):
        return None
    return n / 1000.0 if n > 1000 else n


def scan_hwmon(base: Path | None = None) -> tuple[float, str] | None:
    base = base or HWMON_BASE
    try:
        hwmons = sorted(base.glob("hwmon*"))
    except OSError:
        return None
    for hw in hwmons:
        if _read(hw / "name") != "k10temp":
            continue
        for label in sorted(hw.glob("temp*_label")):
            if _read(label) != "Tctl":
                continue
            temp = _millis_to_celsius(_read(Path(str(label)[:-6] + "_input")))
            if temp is not None:
                return temp, "k10temp/Tctl"
        inputs = sorted(hw.glob("temp*_input"))
        if inputs:
            temp = _millis_to_celsius(_read(inputs[0]))
            if temp is not None:
                return temp, "k10temp"
    return None


def scan_thermal(base: Path | None = None) -> tuple[float, str] | None:
    base = base or THERMAL_BASE
    try:
        zones = sorted(base.glob("thermal_zone*"))
    except OSError:
        return None
    for zone in zones:
        ztype = _read(zone / "type")
        if ztype in THERMAL_TYPES:
            temp = _millis_to_celsius(_read(zone / "temp"))
            if temp is not None:
                return temp, ztype
    for zone in zones:
        raw = _read(zone / "temp")
        if not raw:
            continue
        temp = _millis_to_celsius(raw)
        if temp is not None:
            return temp, _read(zone / "type") or "thermal"
    return None


def read_temperature() -> dict:
    found = scan_hwmon() or scan_thermal()
    if found is None:
        return {"ok": False, "version": 1, "temp_c": 0.0, "sensor": "",
                "error": "Nenhum sensor de CPU encontrado"}
    temp_c, sensor = found
    return {"ok": True, "version": 1, "temp_c": temp_c, "sensor": sensor, "error": None}


def main():
    print(json.dumps(read_temperature(), ensure_ascii=False))


if __name__ == "__main__":
    main()
