#!/usr/bin/env python3
import datetime
import json
import os
import tempfile
from pathlib import Path

import requests

WEATHER_CODES = {
    # Céu limpo / nublado
    "113": "",  # Ensolarado / limpo
    "116": "",  # Parcialmente nublado
    "119": "",  # Nublado
    "122": "",  # Encoberto
    "143": "󰖑",  # Névoa

    # Chuva leve / garoa
    "176": "",  # Pancadas fracas
    "263": "",  # Garoa fraca
    "266": "",  # Garoa
    "281": "",  # Garoa congelante
    "284": "",  # Garoa congelante forte
    "293": "",  # Chuva fraca
    "296": "",  # Chuva moderada
    "299": "",  # Chuva moderada às vezes forte
    "302": "",  # Chuva moderada / forte
    "305": "",  # Chuva forte às vezes moderada
    "308": "",  # Chuva forte
    "311": "",  # Chuva congelante leve
    "314": "",  # Chuva congelante moderada / forte
    "353": "",  # Pancadas fracas
    "356": "",  # Pancadas moderadas / fortes
    "359": "",  # Pancadas fortes

    # Tempestades
    "200": "",  # Trovoada próxima
    "386": "",  # Pancadas com trovoada leves
    "389": "",  # Pancadas com trovoada moderadas / fortes

    # Neve / granizo
    "179": "",  # Neve leve irregular
    "182": "",  # Aguaneve leve
    "185": "",  # Chuvisco congelante leve
    "227": "",  # Nevasca
    "230": "",  # Nevasca forte
    "317": "",  # Aguaneve leve
    "320": "",  # Aguaneve moderada / forte
    "323": "",  # Pancadas de neve leves
    "326": "",  # Pancadas de neve moderadas
    "329": "",  # Pancadas de neve fortes
    "332": "",  # Neve moderada
    "335": "",  # Neve forte
    "338": "",  # Neve intensa
    "350": "",  # Pellets de gelo
    "362": "",  # Pancadas leves de aguaneve
    "365": "",  # Pancadas moderadas / fortes de aguaneve
    "368": "",  # Pancadas leves de neve
    "371": "",  # Pancadas fortes de neve
    "374": "",  # Granizo leve
    "377": "",  # Granizo moderado / forte
    "392": "",  # Pancadas leves de neve com trovoada
    "395": "",  # Pancadas fortes de neve com trovoada

    # Névoa mais densa
    "248": "󰖑",  # Névoa
    "260": "󰖑",  # Névoa congelante
}

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "waybar"
CACHE_FILE = CACHE_DIR / "weather.json"


def get_day_label(date_str: str, index: int) -> str:
    if index == 0:
        return "Hoje"
    if index == 1:
        return "Amanhã"

    try:
        dt = datetime.datetime.strptime(date_str, "%Y-%m-%d")
        weekdays = [
            "Segunda", "Terça", "Quarta", "Quinta",
            "Sexta", "Sábado", "Domingo",
        ]
        return f"{weekdays[dt.weekday()]} ({dt:%d/%m})"
    except ValueError:
        return date_str


def get_location() -> tuple[str, str]:
    # O wttr.in também se localiza sozinho caso location_query fique vazio.
    city_name = "Localização atual"
    location_query = ""

    try:
        geo_req = requests.get(
            "http://ip-api.com/json/",
            timeout=5,
            headers={"User-Agent": "Waybar Weather"},
        )
        geo_req.raise_for_status()
        geo_data = geo_req.json()

        if geo_data.get("status") == "success":
            city_name = geo_data.get("city") or city_name

            lat = geo_data.get("lat")
            lon = geo_data.get("lon")

            if lat is not None and lon is not None:
                location_query = f"{lat},{lon}"
    except (requests.RequestException, ValueError):
        pass

    return city_name, location_query


def get_period(hourly_data: dict, time_str: str) -> tuple[str, str]:
    item = hourly_data.get(time_str, {})

    if not item:
        return "", "--°C"

    icon = WEATHER_CODES.get(str(item.get("weatherCode")), "")
    temp = f"{item.get('tempC', '--')}°C"

    return icon, temp


def save_cache(city_name: str, data: dict) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    cache_data = {
        "city_name": city_name,
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "weather_data": data,
    }

    # Escrita atômica: nunca deixa a Waybar ler um JSON incompleto.
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=CACHE_DIR,
        prefix="weather.",
        suffix=".tmp",
        delete=False,
    ) as temp_file:
        json.dump(cache_data, temp_file, ensure_ascii=False)
        temp_file.write("\n")
        temp_name = temp_file.name

    os.replace(temp_name, CACHE_FILE)


def load_cache() -> dict | None:
    try:
        with CACHE_FILE.open(encoding="utf-8") as file:
            cache = json.load(file)

        if not isinstance(cache.get("weather_data"), dict):
            return None

        return cache
    except (OSError, json.JSONDecodeError):
        return None


def fetch_weather() -> tuple[str, dict]:
    city_name, location_query = get_location()

    response = requests.get(
        f"https://wttr.in/{location_query}?format=j1&lang=pt",
        timeout=10,
        headers={"User-Agent": "Waybar Weather"},
    )
    response.raise_for_status()

    data = response.json()

    # Validação mínima antes de sobrescrever o cache.
    current = data["current_condition"][0]
    if "temp_C" not in current or "weatherCode" not in current:
        raise ValueError("Resposta do wttr.in inválida")

    return city_name, data


def build_output(cache: dict, stale: bool) -> dict:
    city_name = cache.get("city_name", "Localização atual")
    data = cache["weather_data"]

    current = data["current_condition"][0]

    weather_desc = (
        current.get("lang_pt", [{}])[0].get("value")
        or current.get("weatherDesc", [{}])[0].get("value")
        or "Clima desconhecido"
    ).capitalize()

    temp_c = current.get("temp_C", "--")
    feels_like = current.get("FeelsLikeC", "--")
    humidity = current.get("humidity", "--")
    wind = current.get("windspeedKmph", "--")

    current_icon = WEATHER_CODES.get(
        str(current.get("weatherCode")),
        "",
    )

    tooltip_lines = [
        f"<b>{city_name}: {weather_desc}</b>",
        f"Sensação: {feels_like}°C · Umidade: {humidity}% · Vento: {wind} km/h",
        "",
    ]

    for i, day in enumerate(data.get("weather", [])[:3]):
        day_title = get_day_label(day.get("date", ""), i)

        hourly_data = {
            item.get("time"): item
            for item in day.get("hourly", [])
            if item.get("time") is not None
        }

        morning_icon, morning_temp = get_period(hourly_data, "900")
        afternoon_icon, afternoon_temp = get_period(hourly_data, "1200")
        night_icon, night_temp = get_period(hourly_data, "1800")
        dawn_icon, dawn_temp = get_period(hourly_data, "2100")

        tooltip_lines.extend([
            f"<b>{day_title}</b>",
            (
                f"Manhã {morning_icon} {morning_temp}   "
                f"Tarde {afternoon_icon} {afternoon_temp}"
            ),
            (
                f"Noite {night_icon} {night_temp}   "
                f"Madruga {dawn_icon} {dawn_temp}"
            ),
            "",
        ])

    updated_at = cache.get("updated_at", "")
    if updated_at:
        try:
            updated = datetime.datetime.fromisoformat(updated_at)
            tooltip_lines.extend([
                f"<i>Atualizado: {updated:%d/%m às %H:%M}</i>",
            ])
        except ValueError:
            pass

    if stale:
        tooltip_lines.extend([
            "<i>Sem conexão: exibindo última previsão válida.</i>",
        ])

    tooltip_text = "<tt>" + "\n".join(tooltip_lines).strip() + "</tt>"

    return {
        "text": f"{current_icon} {temp_c}°C",
        "tooltip": tooltip_text,
        "class": "weather stale" if stale else "weather",
    }


def main() -> None:
    updated_successfully = False

    try:
        city_name, data = fetch_weather()
        save_cache(city_name, data)
        updated_successfully = True
    except (requests.RequestException, ValueError, KeyError, IndexError):
        pass

    cache = load_cache()

    # Só mostra "--°C" se nunca houve sequer uma atualização válida.
    if cache is None:
        output = {
            "text": " --°C",
            "tooltip": "Previsão indisponível — aguardando primeira atualização.",
            "class": "weather offline",
        }
    else:
        output = build_output(cache, stale=not updated_successfully)

    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
