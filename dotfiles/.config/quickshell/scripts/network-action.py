#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def result(ok, action, error=None, detail=""):
    print(json.dumps({
        "ok": bool(ok),
        "action": action,
        "error": error or None,
        "detail": detail,
    }, ensure_ascii=False))
    return 0 if ok else 1


def friendly_error(stderr, stdout=""):
    raw = (stderr or stdout or "").strip()
    low = raw.lower()

    if not raw:
        return "A operação de rede falhou."

    if "secrets were required" in low or "no secrets" in low:
        return "A credencial necessária não foi fornecida."
    if "activation failed" in low and ("password" in low or "secret" in low):
        return "Não foi possível autenticar. Verifique a senha."
    if "wrong password" in low or "bad password" in low:
        return "Senha incorreta."
    if "no network with ssid" in low or "not found" in low:
        return "A rede não está mais disponível."
    if "connection activation failed" in low:
        return "Não foi possível ativar a conexão."
    if "device" in low and "disconnected" in low:
        return "O dispositivo de rede está desconectado."
    if "not authorized" in low or "permission" in low:
        return "Sem permissão para executar esta operação."
    if "timeout" in low or "timed out" in low:
        return "A operação de rede expirou."

    # Keep the popup useful without dumping a giant nmcli message.
    first = raw.splitlines()[0].strip()
    return first[:180]


def run_nmcli(action, args, input_data=None):
    try:
        p = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            input=input_data,
            timeout=40,
        )
    except subprocess.TimeoutExpired:
        return result(False, action, "A operação de rede expirou.")
    except Exception as e:
        return result(False, action, "Não foi possível executar o NetworkManager.", str(e))

    if p.returncode == 0:
        return result(True, action)

    return result(False, action, friendly_error(p.stderr, p.stdout), p.stderr.strip())


def spawn(action, commands):
    for cmd in commands:
        try:
            subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return result(True, action)
        except Exception:
            pass
    return result(False, action, "Não foi possível abrir o aplicativo solicitado.")


def main():
    if len(sys.argv) < 2:
        return result(False, "", "Ação de rede inválida.")

    action = sys.argv[1]

    if action == "wifi-on":
        return run_nmcli(action, ["nmcli", "radio", "wifi", "on"])

    if action == "wifi-off":
        return run_nmcli(action, ["nmcli", "radio", "wifi", "off"])

    if action == "disconnect":
        if len(sys.argv) < 3 or not sys.argv[2]:
            return result(False, action, "Dispositivo Wi‑Fi desconhecido.")
        return run_nmcli(action, ["nmcli", "device", "disconnect", sys.argv[2]])

    if action == "connect-saved":
        if len(sys.argv) < 3:
            return result(False, action, "Perfil de conexão inválido.")
        return run_nmcli(action, ["nmcli", "connection", "up", "uuid", sys.argv[2]])

    if action == "connect-open":
        if len(sys.argv) < 3:
            return result(False, action, "SSID inválida.")
        return run_nmcli(action, ["nmcli", "device", "wifi", "connect", sys.argv[2]])

    if action == "connect-password":
        if len(sys.argv) < 3:
            return result(False, action, "SSID ou senha inválidos.")
        ssid = sys.argv[2]
        password = sys.stdin.readline().removesuffix("\n")
        if not password:
            return result(False, action, "SSID ou senha inválidos.")
        return run_nmcli(
            action,
            ["nmcli", "--ask", "device", "wifi", "connect", ssid],
            input_data=password + "\n",
        )

    if action == "wifi-qr":
        p = subprocess.run(
            ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"],
            capture_output=True,
            text=True
        )
        ssid = ""
        for line in p.stdout.splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and parts[1] in ("802-11-wireless", "wifi"):
                ssid = parts[0]
                break
        if not ssid:
            return result(False, action, "Nenhuma rede Wi-Fi ativa.")

        p = subprocess.run(
            ["nmcli", "--show-secrets", "-g", "802-11-wireless-security.psk", "connection", "show", ssid],
            capture_output=True,
            text=True
        )
        psk = p.stdout.strip()
        sec = "WPA" if psk else "nopass"
        payload = f"WIFI:T:{sec};S:{ssid};P:{psk};;"
        p = subprocess.run(
            ["qrencode", "-s", "6", "-m", "2", "-t", "PNG", "-o", "-"],
            input=payload.encode("utf-8"),
            capture_output=True,
            timeout=10,
        )
        if p.returncode == 0:
            try:
                runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir())
                private_dir = runtime_dir / f"quickshell-{os.getuid()}"
                private_dir.mkdir(mode=0o700, exist_ok=True)
                if private_dir.stat().st_uid != os.getuid():
                    raise OSError("private runtime directory has another owner")
                private_dir.chmod(0o700)
                out_path = private_dir / "wifi-qr.png"
                flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW
                fd = os.open(out_path, flags, 0o600)
                with os.fdopen(fd, "wb") as image_file:
                    os.fchmod(image_file.fileno(), 0o600)
                    image_file.write(p.stdout)
            except OSError:
                return result(False, action, "Não foi possível salvar o QR code.")
            print(json.dumps({
                "ok": True,
                "action": action,
                "path": str(out_path),
                "ssid": ssid,
                "password": psk
            }, ensure_ascii=False))
            return 0
        return result(False, action, "Não foi possível gerar o QR code.")

    if action == "copy":
        text = sys.stdin.readline().removesuffix("\n")
        if not text:
            return result(False, action, "Nenhum texto para copiar.")
        try:
            p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE, text=True)
            p.communicate(input=text)
            return result(True, action)
        except Exception as e:
            return result(False, action, "Falha ao copiar para a área de transferência.", str(e))

    if action == "open-portal":
        return spawn(action, [
            ["xdg-open", "http://ping.archlinux.org/nm-check.txt"],
            ["xdg-open", "http://captive.apple.com"],
        ])

    if action == "vpn-up":
        if len(sys.argv) < 3:
            return result(False, action, "Perfil VPN inválido.")
        return run_nmcli(action, ["nmcli", "connection", "up", "uuid", sys.argv[2]])

    if action == "vpn-down":
        if len(sys.argv) < 3:
            return result(False, action, "Perfil VPN inválido.")
        return run_nmcli(action, ["nmcli", "connection", "down", "uuid", sys.argv[2]])

    if action == "editor":
        return spawn(action, [
            ["uwsm", "app", "--", "nm-connection-editor"],
            ["nm-connection-editor"],
        ])

    return result(False, action, "Ação de rede desconhecida.")


if __name__ == "__main__":
    raise SystemExit(main())
