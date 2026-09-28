#!/usr/bin/env python3
import os
import sys
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


kc = _import_script("kdeconnect_status", "kdeconnect-status.py")


class TestKDEConnectParsers(unittest.TestCase):
    def test_parse_list_human(self):
        text = (
            "- Pixel 8: abc123def456 on 192.168.1.10 via lan (paired and reachable)\n"
            "- Tablet: xyz789 (paired)\n"
            "- Laptop: qwe123 (reachable)\n"
            "- Old Phone: old999\n"
        )
        devs = kc.parse_list_human(text)
        self.assertEqual(len(devs), 4)
        by_id = {d["id"]: d for d in devs}
        self.assertTrue(by_id["abc123def456"]["paired"])
        self.assertTrue(by_id["abc123def456"]["reachable"])
        self.assertEqual(by_id["abc123def456"]["name"], "Pixel 8")
        self.assertTrue(by_id["xyz789"]["paired"])
        self.assertFalse(by_id["xyz789"]["reachable"])
        self.assertFalse(by_id["qwe123"]["paired"])
        self.assertTrue(by_id["qwe123"]["reachable"])
        self.assertFalse(by_id["old999"]["paired"])
        self.assertFalse(by_id["old999"]["reachable"])

    def test_parse_list_human_ignores_noise(self):
        text = "1 device found\n\n"
        self.assertEqual(kc.parse_list_human(text), [])
        self.assertEqual(kc.parse_list_human(""), [])

    def test_parse_id_only(self):
        self.assertEqual(kc.parse_id_only("abc\nxyz\n"), ["abc", "xyz"])
        self.assertEqual(kc.parse_id_only(""), [])

    def test_parse_battery(self):
        self.assertEqual(kc.parse_battery_gdbus_output("(int32 85,)"), 85)
        self.assertEqual(kc.parse_battery_gdbus_output("(<int32 42>,)"), 42)
        self.assertEqual(kc.parse_battery_gdbus_output(""), -1)
        self.assertEqual(kc.parse_battery_gdbus_output("no numbers here"), -1)

    def test_build_payload_ordering(self):
        devs = [
            {"id": "b", "name": "Beta", "reachable": False, "paired": True,
             "battery": -1, "charging": False},
            {"id": "a", "name": "Alpha", "reachable": True, "paired": True,
             "battery": 80, "charging": False},
        ]
        p = kc.build_payload(devs, True, True, True, None)
        self.assertTrue(p["ok"])
        self.assertEqual(p["version"], 1)
        self.assertTrue(p["visible"])
        self.assertEqual(p["reachable_count"], 1)
        self.assertEqual(p["devices"][0]["id"], "a")
        self.assertIn("Alpha", p["tooltip"])

    def test_build_payload_missing_binary(self):
        p = kc.build_payload([], False, False, False, "kdeconnect-cli não encontrado")
        self.assertFalse(p["ok"])
        self.assertFalse(p["available"])
        self.assertFalse(p["visible"])
        self.assertIsInstance(p["error"], str)


if __name__ == "__main__":
    unittest.main()
