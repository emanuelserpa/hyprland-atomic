#!/usr/bin/env python3
"""
Night Light Manager for Quickshell Desktop Shell.
Calculates solar times (sunrise/sunset) using location from weather configuration,
and controls display color temperature via hyprsunset or wlsunset.
Output envelope adheres strictly to {"ok": bool, "error": str | None, ...}.
"""

import argparse
import datetime
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

sys.dont_write_bytecode = True

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "quickshell"
STATE_FILE = STATE_DIR / "nightlight.json"
WEATHER_STATE_FILE = STATE_DIR / "weather.json"
WEATHER_CACHE_FILE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "waybar" / "weather.json"

HYPR_CONFIG_DIR = Path.home() / ".config" / "hypr"
HYPR_SUNSET_CONF = HYPR_CONFIG_DIR / "hyprsunset.conf"

DEFAULT_NIGHT_TEMP = 4000
DEFAULT_DAY_TEMP = 6500


def get_sun_times(lat: float, lon: float, date: datetime.date | None = None) -> tuple[str, str]:
    """
    Calcula o nascer e pôr do sol local para a data e coordenadas especificadas
    usando o algoritmo solar padrão da NOAA.
    """
    if date is None:
        date = datetime.date.today()

    day_of_year = date.timetuple().tm_yday
    lng_hour = lon / 15.0
    results = {}

    for is_sunrise, name in [(True, "sunrise"), (False, "sunset")]:
        t = day_of_year + ((6.0 if is_sunrise else 18.0) - lng_hour) / 24.0
        M = (0.9856 * t) - 3.289
        L = (M + (1.916 * math.sin(math.radians(M))) + (0.020 * math.sin(math.radians(2 * M))) + 282.634) % 360
        RA = math.degrees(math.atan(0.91764 * math.tan(math.radians(L)))) % 360
        L_quad = math.floor(L / 90.0) * 90.0
        RA_quad = math.floor(RA / 90.0) * 90.0
        RA = (RA + (L_quad - RA_quad)) / 15.0
        sinDec = 0.39782 * math.sin(math.radians(L))
        cosDec = math.cos(math.asin(sinDec))
        cosH = (math.cos(math.radians(90.833)) - (sinDec * math.sin(math.radians(lat)))) / (cosDec * math.cos(math.radians(lat)))

        if cosH > 1:
            results[name] = "06:00"
            continue
        if cosH < -1:
            results[name] = "18:00"
            continue

        H = (360.0 - math.degrees(math.acos(cosH))) if is_sunrise else math.degrees(math.acos(cosH))
        H = H / 15.0
        T = H + RA - (0.06571 * t) - 6.622
        UT = (T - lng_hour) % 24.0

        now = datetime.datetime.now()
        local_offset = (now.astimezone().utcoffset() or datetime.timedelta(0)).total_seconds() / 3600.0
        local_hour = (UT + local_offset) % 24.0
        h = int(local_hour)
        m = int(round((local_hour - h) * 60))
        if m >= 60:
            h = (h + 1) % 24
            m = 0
        results[name] = f"{h:02d}:{m:02d}"

    return results.get("sunrise", "05:30"), results.get("sunset", "17:30")


def is_night_time(sunrise_str: str, sunset_str: str, now_time: datetime.time | None = None) -> bool:
    """Verifica se o momento atual está entre o pôr e o nascer do sol."""
    now = now_time if now_time is not None else datetime.datetime.now().time()
    sh, sm = map(int, sunrise_str.split(":"))
    eh, em = map(int, sunset_str.split(":"))
    sunrise = datetime.time(sh, sm)
    sunset = datetime.time(eh, em)

    if sunset > sunrise:
        return now < sunrise or now >= sunset
    return sunset <= now < sunrise


def get_weather_location() -> dict:
    """
    Obtém a localização (cidade, latitude, longitude) a partir da configuração de clima.
    Prioridade: 1) weather.json state, 2) waybar cache, 3) ip-api fallback, 4) coordenadas padrão.
    """
    # 1. ~/.local/state/quickshell/weather.json
    try:
        if WEATHER_STATE_FILE.is_file():
            data = json.loads(WEATHER_STATE_FILE.read_text(encoding="utf-8"))
            selected = str(data.get("selected", "auto"))
            cities = data.get("cities", [])
            for city in cities:
                if city.get("id") == selected:
                    lat = float(city.get("latitude"))
                    lon = float(city.get("longitude"))
                    name = str(city.get("name", "Localização"))
                    region = str(city.get("region", ""))
                    display = f"{name}, {region}" if region else name
                    return {
                        "city": display,
                        "latitude": round(lat, 5),
                        "longitude": round(lon, 5),
                        "source": "weather_state",
                    }
            # Se for "auto" mas houver cidades salvas, usa a primeira como referência se offline
            if selected == "auto" and cities:
                first = cities[0]
                lat = float(first.get("latitude"))
                lon = float(first.get("longitude"))
                name = str(first.get("name", "Localização"))
                region = str(first.get("region", ""))
                display = f"{name}, {region}" if region else name
                return {
                    "city": display,
                    "latitude": round(lat, 5),
                    "longitude": round(lon, 5),
                    "source": "weather_cities",
                }
    except Exception:
        pass

    # 2. Fallback geoip se auto e nada configurado
    try:
        import urllib.request
        req = urllib.request.Request("http://ip-api.com/json/", headers={"User-Agent": "Quickshell-NightLight"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            geo_data = json.loads(resp.read().decode("utf-8"))
            if geo_data.get("status") == "success":
                city = geo_data.get("city", "Localização automática")
                lat = float(geo_data.get("lat"))
                lon = float(geo_data.get("lon"))
                return {
                    "city": city,
                    "latitude": round(lat, 5),
                    "longitude": round(lon, 5),
                    "source": "ip_geo",
                }
    except Exception:
        pass

    # 3. Fallback seguro padrão
    return {
        "city": "Tururu, Ceará",
        "latitude": -3.58083,
        "longitude": -39.43722,
        "source": "fallback",
    }


def detect_backend() -> str:
    """Detecta a ferramenta de ajuste de gama adequada para o compositor."""
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    has_hyprsunset = shutil.which("hyprsunset") is not None
    has_wlsunset = shutil.which("wlsunset") is not None

    if "Hyprland" in desktop and has_hyprsunset:
        return "hyprsunset"
    if has_wlsunset:
        return "wlsunset"
    if has_hyprsunset:
        return "hyprsunset"
    return "none"


def read_state() -> dict:
    """Lê o estado do Night Light."""
    state = {
        "enabled": False,
        "night_temp": DEFAULT_NIGHT_TEMP,
        "day_temp": DEFAULT_DAY_TEMP,
    }
    try:
        if STATE_FILE.is_file():
            data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                state.update(data)
    except Exception:
        pass
    return state


def write_state(state: dict) -> None:
    """Salva o estado atomicamente."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    temp_file = STATE_FILE.with_suffix(".tmp")
    temp_file.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temp_file.replace(STATE_FILE)


def get_running_pids() -> list[int]:
    """Retorna PIDs de instâncias ativas do hyprsunset ou wlsunset."""
    pids = []
    for binary in ["hyprsunset", "wlsunset"]:
        try:
            res = subprocess.run(["pgrep", "-x", binary], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                for line in res.stdout.strip().splitlines():
                    try:
                        pid = int(line.strip())
                        if pid != os.getpid():
                            pids.append(pid)
                    except ValueError:
                        pass
        except Exception:
            pass
    return sorted(list(set(pids)))


def stop_daemons(reset_identity: bool = True) -> None:
    """Interrompe qualquer daemon de luz noturna e restaura a gama para normal se solicitado."""
    for binary in ["hyprsunset", "wlsunset"]:
        subprocess.run(["pkill", "-x", binary], capture_output=True)

    time.sleep(0.1)

    # Restaura matriz de identidade apenas se solicitado (ex: ao desligar)
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    if reset_identity and "Hyprland" in desktop and shutil.which("hyprsunset"):
        try:
            p = subprocess.Popen(
                ["hyprsunset", "-i"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            time.sleep(0.2)
            p.terminate()
            try:
                p.wait(timeout=0.4)
            except Exception:
                p.kill()
        except Exception:
            pass


def start_daemon(backend: str, lat: float, lon: float, sunrise: str, sunset: str, night_temp: int, day_temp: int) -> bool:
    """Inicia o daemon correspondente configurado com os horários e coordenadas."""
    stop_daemons(reset_identity=False)

    if backend == "hyprsunset":
        HYPR_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        conf_content = f"""# Auto-generated by Quickshell Night Light from weather location
# Location coordinates: {lat}, {lon}
# Sunrise: {sunrise} | Sunset: {sunset}

profile {{
    time = {sunrise}
    identity = true
}}

profile {{
    time = {sunset}
    temperature = {night_temp}
}}
"""
        HYPR_SUNSET_CONF.write_text(conf_content, encoding="utf-8")
        try:
            subprocess.Popen(
                ["hyprsunset"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            time.sleep(0.2)
            return True
        except Exception:
            return False

    elif backend == "wlsunset":
        try:
            subprocess.Popen(
                ["wlsunset", "-l", str(lat), "-L", str(lon), "-t", str(night_temp), "-T", str(day_temp)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            time.sleep(0.2)
            return True
        except Exception:
            return False

    return False


def get_status() -> dict:
    """Retorna o estado detalhado da luz noturna."""
    state = read_state()
    location = get_weather_location()
    backend = detect_backend()
    sunrise, sunset = get_sun_times(location["latitude"], location["longitude"])
    is_night = is_night_time(sunrise, sunset)
    pids = get_running_pids()
    is_running = len(pids) > 0

    enabled = bool(state.get("enabled", False))
    current_temp = state.get("night_temp", DEFAULT_NIGHT_TEMP) if (enabled and is_night) else state.get("day_temp", DEFAULT_DAY_TEMP)

    return {
        "ok": True,
        "version": 1,
        "error": None,
        "enabled": enabled,
        "active": (enabled and is_night and is_running),
        "running": is_running,
        "is_night": is_night,
        "backend": backend,
        "city": location["city"],
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "sunrise": sunrise,
        "sunset": sunset,
        "night_temp": state.get("night_temp", DEFAULT_NIGHT_TEMP),
        "day_temp": state.get("day_temp", DEFAULT_DAY_TEMP),
        "current_temp": current_temp,
        "pids": pids,
    }


def cmd_on() -> dict:
    """Ativa a luz noturna."""
    state = read_state()
    state["enabled"] = True
    write_state(state)

    status = get_status()
    start_daemon(
        backend=status["backend"],
        lat=status["latitude"],
        lon=status["longitude"],
        sunrise=status["sunrise"],
        sunset=status["sunset"],
        night_temp=status["night_temp"],
        day_temp=status["day_temp"],
    )
    return get_status()


def cmd_off() -> dict:
    """Desativa a luz noturna."""
    state = read_state()
    state["enabled"] = False
    write_state(state)
    stop_daemons()
    return get_status()


def cmd_toggle() -> dict:
    """Alterna entre ligado e desligado."""
    state = read_state()
    if state.get("enabled", False):
        return cmd_off()
    return cmd_on()


def cmd_sync() -> dict:
    """Sincroniza a configuração com a localização atual do clima."""
    state = read_state()
    if state.get("enabled", False):
        status = get_status()
        start_daemon(
            backend=status["backend"],
            lat=status["latitude"],
            lon=status["longitude"],
            sunrise=status["sunrise"],
            sunset=status["sunset"],
            night_temp=status["night_temp"],
            day_temp=status["day_temp"],
        )
    return get_status()


def main() -> int:
    parser = argparse.ArgumentParser(description="Gerenciador de Luz Noturna (wlsunset/hyprsunset) do Quickshell")
    parser.add_argument("action", nargs="?", default="status", choices=["status", "on", "off", "toggle", "sync"], help="Ação a executar")
    args = parser.parse_args()

    try:
        if args.action == "on":
            res = cmd_on()
        elif args.action == "off":
            res = cmd_off()
        elif args.action == "toggle":
            res = cmd_toggle()
        elif args.action == "sync":
            res = cmd_sync()
        else:
            res = get_status()
    except Exception as e:
        res = {"ok": False, "version": 1, "error": str(e)}

    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0 if res.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
