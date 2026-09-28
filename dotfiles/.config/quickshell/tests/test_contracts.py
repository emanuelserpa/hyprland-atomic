#!/usr/bin/env python3
import io
import json
import os
import sys
from unittest.mock import MagicMock, patch
sys.dont_write_bytecode = True
import unittest

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts"))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import importlib.util

def _import_script(mod_name, file_name):
    path = os.path.join(SCRIPT_DIR, file_name)
    spec = importlib.util.spec_from_file_location(mod_name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

bt_mod = _import_script("bluetooth_status", "bluetooth-status.py")
bt_ctl_mod = _import_script("bt_ctl", "bt_ctl.py")
bt_action_mod = _import_script("bluetooth_action", "bluetooth-action.py")
net_mod = _import_script("network_status", "network-status.py")
net_action_mod = _import_script("network_action", "network-action.py")
energy_mod = _import_script("energy_profile", "energy-profile.py")
charge_limit_mod = _import_script("battery_charge_limit", "battery-charge-limit.py")
printer_status_mod = _import_script("printer_status", "printer-status.py")
printer_action_mod = _import_script("printer_action", "printer-action.py")
weather_cities_mod = _import_script("weather_cities", "weather-cities.py")
screen_rec_mod = _import_script("screen_recording", "screen-recording.py")
game_mod = _import_script("game_status", "game-status.py")


class TestContracts(unittest.TestCase):
    """Regression tests verifying standardized JSON helper envelopes ({"ok": bool, "error": str | None, ...})."""

    def test_energy_profile_contract(self):
        # 1. Active / available state contract
        state = energy_mod.current_state()
        self.assertIn("ok", state)
        self.assertIsInstance(state["ok"], bool)
        self.assertIn("error", state)
        if state["ok"]:
            self.assertIsNone(state["error"])
        else:
            self.assertIsInstance(state["error"], str)
        self.assertIn("available", state)
        self.assertIn("profiles", state)
        self.assertIsInstance(state["profiles"], list)
        self.assertIn("active", state)
        self.assertIn("backend", state)

        # 2. Fallback state when no backend is available
        with patch.object(energy_mod, "ppd_state", return_value=None), \
             patch.object(energy_mod, "platform_state", return_value=None):
            fallback = energy_mod.current_state()
            self.assertFalse(fallback["ok"])
            self.assertFalse(fallback["available"])
            self.assertEqual(fallback["backend"], "none")
            self.assertIsInstance(fallback["error"], str)
            self.assertGreater(len(fallback["error"]), 0)

    def test_battery_charge_limit_contract(self):
        # 1. Live status envelope on this host
        state = charge_limit_mod.current_state()
        self.assertIn("ok", state)
        self.assertIsInstance(state["ok"], bool)
        self.assertIn("error", state)
        self.assertIn("version", state)
        self.assertEqual(state["version"], charge_limit_mod.VERSION)
        self.assertIn("available", state)
        self.assertIn("limit", state)
        self.assertIsInstance(state["limit"], int)
        self.assertIn("on_ac", state)
        if state["ok"]:
            self.assertIsNone(state["error"])
            self.assertIn(state["limit"], (80, 100))
        else:
            self.assertIsInstance(state["error"], str)

        # 2. Missing sensor fallback
        with patch.object(charge_limit_mod, "read_int_file", return_value=None):
            missing = charge_limit_mod.current_state()
            self.assertFalse(missing["ok"])
            self.assertFalse(missing["available"])
            self.assertEqual(missing["limit"], 0)
            self.assertIsInstance(missing["error"], str)

        # 3. Invalid set argument envelope (no side effects)
        with patch.object(charge_limit_mod.sys, "argv", ["battery-charge-limit.py", "set", "90"]):
            buf = io.StringIO()
            with patch("sys.stdout", buf):
                code = charge_limit_mod.main()
            self.assertEqual(code, 2)
            payload = json.loads(buf.getvalue())
            self.assertFalse(payload["ok"])
            self.assertIn("80", payload["error"])

        # 4. Refuses to change limit while unplugged (no sudo invoked)
        with patch.object(charge_limit_mod, "on_ac", return_value=False), \
             patch.object(charge_limit_mod, "run") as mock_run:
            ok, err = charge_limit_mod.apply_limit(100)
            self.assertFalse(ok)
            self.assertIn("carregador", err)
            mock_run.assert_not_called()
        # 1. Real / current host state
        status = printer_status_mod.get_status()
        self.assertIn("ok", status)
        self.assertIsInstance(status["ok"], bool)
        self.assertIn("error", status)
        if status["ok"]:
            self.assertIsNone(status["error"])
        else:
            self.assertIsInstance(status["error"], str)
        self.assertIn("available", status)
        self.assertIn("visible", status)
        self.assertIn("printers", status)
        self.assertIsInstance(status["printers"], list)
        self.assertIn("jobs", status)
        self.assertIsInstance(status["jobs"], list)
        self.assertIn("job_count", status)
        self.assertIsInstance(status["job_count"], int)
        self.assertIn("tooltip", status)

        # 2. Missing lpstat fallback
        with patch("shutil.which", return_value=None):
            missing = printer_status_mod.get_status()
            self.assertFalse(missing["ok"])
            self.assertFalse(missing["available"])
            self.assertFalse(missing["visible"])
            self.assertEqual(missing["printers"], [])
            self.assertEqual(missing["jobs"], [])
            self.assertEqual(missing["job_count"], 0)
            self.assertEqual(missing["error"], "CUPS/lpstat não encontrado")

    def test_bluetooth_status_contract(self):
        # 1. Parse valid controller output
        sample_show = (
            "Controller 14:5A:FC:18:15:D2 (public)\n"
            "\tName: hostname\n"
            "\tAlias: t14\n"
            "\tPowered: yes\n"
            "\tPairable: yes\n"
        )
        res = bt_mod.parse_bt_show(sample_show, rc=0)
        self.assertIn("ok", res)
        self.assertTrue(res["ok"])
        self.assertTrue(res["available"])
        self.assertIsNone(res["error"])
        self.assertTrue(res["powered"])

        # 2. Parse missing controller / error
        res_fail = bt_mod.parse_bt_show("", rc=1, err="No default controller available")
        self.assertIn("ok", res_fail)
        self.assertFalse(res_fail["ok"])
        self.assertFalse(res_fail["available"])
        self.assertIsInstance(res_fail["error"], str)
        self.assertEqual(res_fail["error"], "No default controller available")

    def test_network_status_contract(self):
        # 1. NM unavailable failure path
        with patch.object(net_mod, "run", return_value=(1, "", "NetworkManager not running")):
            buf = io.StringIO()
            with patch("sys.stdout", buf):
                net_mod.main()
            data = json.loads(buf.getvalue())
            self.assertIn("ok", data)
            self.assertFalse(data["ok"])
            self.assertEqual(data["status"], "error")
            self.assertEqual(data["error"], "NetworkManager not running")
            self.assertEqual(data["text"], "󰤭")
            self.assertEqual(data["tooltip"], "NetworkManager indisponível")

        # 2. NM available success path
        with patch.object(net_mod, "run", side_effect=[
            (0, "enabled", ""),  # general wifi
            (0, "192.168.1.15/24", ""),  # ip
            (0, "*:60:5180 MHz", ""),  # wifi info
            (0, "full", ""),  # connectivity
        ]), patch.object(net_mod, "lines", side_effect=[
            ["MyWiFi:uuid-1:802-11-wireless"],  # connection show
            ["MyWiFi:uuid-1:802-11-wireless:wlan0"],  # connection show --active
        ]):
            buf = io.StringIO()
            with patch("sys.stdout", buf):
                net_mod.main()
            data = json.loads(buf.getvalue())
            self.assertIn("ok", data)
            self.assertTrue(data["ok"])
            self.assertIsNone(data["error"])
            self.assertEqual(data["status"], "ok")
            self.assertTrue(data["wifi_enabled"])
            self.assertEqual(data["active_ssid"], "MyWiFi")

    def test_bt_ctl_runner_contract(self):
        import subprocess as sp

        def fake_proc(rc, out="", err=""):
            proc = MagicMock()
            proc.returncode = rc
            proc.stdout = out
            proc.stderr = err
            return proc

        # 1. Success passes through untouched (single invocation)
        with patch.object(bt_ctl_mod.subprocess, "run",
                          return_value=fake_proc(0, "Controller XX", "")) as mock_run, \
             patch.object(bt_ctl_mod.time, "sleep"):
            rc, out, err = bt_ctl_mod.run_bt(["bluetoothctl", "show"], timeout=2)
            self.assertEqual(rc, 0)
            self.assertEqual(out, "Controller XX")
            self.assertEqual(mock_run.call_count, 1)

        # 2. SIGABRT-style death (rc -6 / 134) retries once, then succeeds
        for death_rc in (-6, 134):
            with patch.object(bt_ctl_mod.subprocess, "run",
                              side_effect=[fake_proc(death_rc), fake_proc(0, "ok", "")]) as mock_run, \
                 patch.object(bt_ctl_mod.time, "sleep"):
                rc, out, _ = bt_ctl_mod.run_bt(["bluetoothctl", "show"], timeout=2)
                self.assertEqual(rc, 0)
                self.assertEqual(out, "ok")
                self.assertEqual(mock_run.call_count, 2)

        # 3. Persistent crash surfaces the last result (no hang, no raise)
        with patch.object(bt_ctl_mod.subprocess, "run",
                          return_value=fake_proc(-6)) as mock_run, \
             patch.object(bt_ctl_mod.time, "sleep"):
            rc, _, _ = bt_ctl_mod.run_bt(["bluetoothctl", "show"], timeout=2)
            self.assertEqual(rc, -6)
            self.assertEqual(mock_run.call_count, 2)

        # 4. Timeout maps to rc 124 without raising
        with patch.object(bt_ctl_mod.subprocess, "run",
                          side_effect=sp.TimeoutExpired(cmd="x", timeout=1)):
            rc, _, err = bt_ctl_mod.run_bt(["bluetoothctl", "show"], timeout=1)
            self.assertEqual(rc, 124)
            self.assertIn("tempo", err)

    def test_bluetooth_action_contract(self):
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            code = bt_action_mod.result(True, "power-on")
        self.assertEqual(code, 0)
        payload = json.loads(buf.getvalue())
        self.assertIn("ok", payload)
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["action"], "power-on")
        self.assertIsNone(payload["error"])

        buf_err = io.StringIO()
        with patch("sys.stdout", buf_err):
            code = bt_action_mod.result(False, "power-on", "Dispositivo indisponível.")
        self.assertEqual(code, 1)
        payload_err = json.loads(buf_err.getvalue())
        self.assertFalse(payload_err["ok"])
        self.assertEqual(payload_err["action"], "power-on")
        self.assertEqual(payload_err["error"], "Dispositivo indisponível.")

    def test_network_action_contract(self):
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            code = net_action_mod.result(True, "wifi-on")
        self.assertEqual(code, 0)
        payload = json.loads(buf.getvalue())
        self.assertIn("ok", payload)
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["action"], "wifi-on")
        self.assertIsNone(payload["error"])

        buf_err = io.StringIO()
        with patch("sys.stdout", buf_err):
            code = net_action_mod.result(False, "wifi-on", "A operação de rede expirou.", "timeout")
        self.assertEqual(code, 1)
        payload_err = json.loads(buf_err.getvalue())
        self.assertFalse(payload_err["ok"])
        self.assertEqual(payload_err["error"], "A operação de rede expirou.")
        self.assertEqual(payload_err["detail"], "timeout")

    def test_printer_action_contract(self):
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            printer_action_mod.out(True)
        payload = json.loads(buf.getvalue())
        self.assertTrue(payload["ok"])
        self.assertIsNone(payload["error"])

        buf_err = io.StringIO()
        with patch("sys.stdout", buf_err):
            printer_action_mod.out(False, "ID do trabalho ausente.")
        payload_err = json.loads(buf_err.getvalue())
        self.assertFalse(payload_err["ok"])
        self.assertEqual(payload_err["error"], "ID do trabalho ausente.")

    def test_weather_cities_contract(self):
        # 1. public_state envelope
        mock_state = {
            "selected": "auto",
            "cities": [
                {
                    "id": "tururu-cear-brasil--3.581--39.437",
                    "name": "Tururu",
                    "region": "Ceará",
                    "country": "Brasil",
                    "latitude": -3.58083,
                    "longitude": -39.43722,
                }
            ]
        }
        pub = weather_cities_mod.public_state(mock_state)
        self.assertIn("ok", pub)
        self.assertTrue(pub["ok"])
        self.assertIsNone(pub["error"])
        self.assertEqual(pub["selected"], "auto")
        self.assertEqual(pub["count"], 2)  # auto + 1 city
        self.assertEqual(len(pub["cities"]), 2)

        # 2. cmd_search short query
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            args = MagicMock()
            args.query = "a"
            weather_cities_mod.cmd_search(args)
        res = json.loads(buf.getvalue())
        self.assertTrue(res["ok"])
        self.assertEqual(res["results"], [])
        self.assertIsNone(res["error"])

        # 3. cmd_search network failure envelope
        buf_err = io.StringIO()
        with patch("requests.get", side_effect=weather_cities_mod.requests.RequestException("ConnError")), \
             patch("sys.stdout", buf_err), \
             self.assertRaises(SystemExit):
            args = MagicMock()
            args.query = "Fortaleza"
            weather_cities_mod.cmd_search(args)
        res_err = json.loads(buf_err.getvalue())
        self.assertFalse(res_err["ok"])
        self.assertEqual(res_err["results"], [])
        self.assertIn("RequestException", res_err["error"])

    def test_game_status_contract(self):
        import tempfile

        # 1. No games: empty envelope, inactive
        with tempfile.TemporaryDirectory() as proc_dir, \
             tempfile.TemporaryDirectory() as apps_dir:
            idle = game_mod.get_status(proc_root=proc_dir, steamapps_dir=apps_dir)
            self.assertTrue(idle["ok"])
            self.assertFalse(idle["active"])
            self.assertEqual(idle["count"], 0)
            self.assertEqual(idle["games"], [])
            self.assertIsNone(idle["error"])

        # 2. Fake game process + manifest resolves the display name
        with tempfile.TemporaryDirectory() as proc_dir, \
             tempfile.TemporaryDirectory() as apps_dir:
            pid_dir = os.path.join(proc_dir, "4242")
            os.mkdir(pid_dir)
            with open(os.path.join(pid_dir, "cmdline"), "wb") as fh:
                fh.write(b"/home/u/.local/share/Steam/ubuntu12_32/reaper\0SteamLaunch\0AppId=228980\0steam_app_228980\0")
            with open(os.path.join(apps_dir, "appmanifest_228980.acf"), "w") as fh:
                fh.write('\t"name"\t\t"Pinball FX"\n')
            busy = game_mod.get_status(proc_root=proc_dir, steamapps_dir=apps_dir)
            self.assertTrue(busy["ok"])
            self.assertTrue(busy["active"])
            self.assertEqual(busy["count"], 1)
            self.assertEqual(busy["games"][0]["app_id"], "228980")
            self.assertEqual(busy["games"][0]["name"], "Pinball FX")

        # 3. Unknown app id falls back to a generic label
        with tempfile.TemporaryDirectory() as proc_dir, \
             tempfile.TemporaryDirectory() as apps_dir:
            pid_dir = os.path.join(proc_dir, "9001")
            os.mkdir(pid_dir)
            with open(os.path.join(pid_dir, "cmdline"), "wb") as fh:
                fh.write(b"steam_app_999999\0")
            unknown = game_mod.get_status(proc_root=proc_dir, steamapps_dir=apps_dir)
            self.assertTrue(unknown["active"])
            self.assertEqual(unknown["games"][0]["name"], "App 999999")

    def test_screen_recording_contract(self):
        st = screen_rec_mod.status()
        self.assertIn("ok", st)
        self.assertIsInstance(st["ok"], bool)
        self.assertIn("active", st)
        self.assertIsInstance(st["active"], bool)

    def test_compositor_dispatch_contract(self):
        script_path = os.path.join(SCRIPT_DIR, "compositor-dispatch.sh")
        self.assertTrue(os.path.isfile(script_path))
        self.assertTrue(os.access(script_path, os.X_OK))

        import subprocess
        res = subprocess.run([script_path], capture_output=True, text=True)
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

        res_invalid = subprocess.run([script_path, "nonexistent_action"], capture_output=True, text=True)
        self.assertEqual(res_invalid.returncode, 1)
        self.assertIn("Unknown action", res_invalid.stderr)

    def test_session_action_contract(self):
        script_path = os.path.join(SCRIPT_DIR, "session-action.sh")
        self.assertTrue(os.path.isfile(script_path))
        self.assertTrue(os.access(script_path, os.X_OK))

        import subprocess
        res = subprocess.run([script_path], capture_output=True, text=True)
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

        res_invalid = subprocess.run([script_path, "nonexistent_action"], capture_output=True, text=True)
        self.assertEqual(res_invalid.returncode, 1)
        self.assertIn("Unknown session action", res_invalid.stderr)


    def test_envelope_version_field(self):
        # Todo envelope {"ok": ...} carrega version == 1 (regra de contrato).
        import contextlib

        temp_mod = _import_script("temperature_status", "temperature-status.py")
        temp_res = temp_mod.read_temperature()
        self.assertIn("version", temp_res)
        self.assertEqual(temp_res["version"], 1)

        energy_mod = _import_script("energy_profile", "energy-profile.py")
        energy_res = energy_mod.current_state()
        self.assertEqual(energy_res.get("version"), 1)

        bt_action_mod = _import_script("bluetooth_action", "bluetooth-action.py")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            bt_action_mod.result(True, "probe")
        self.assertEqual(json.loads(buf.getvalue())["version"], 1)

        pr_action_mod = _import_script("printer_action", "printer-action.py")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            pr_action_mod.out(False, "probe")
        self.assertEqual(json.loads(buf.getvalue())["version"], 1)


if __name__ == "__main__":
    unittest.main()
