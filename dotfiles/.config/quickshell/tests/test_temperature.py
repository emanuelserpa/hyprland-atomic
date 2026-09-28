#!/usr/bin/env python3
import importlib.util
import sys
import unittest
import unittest.mock
from pathlib import Path

sys.dont_write_bytecode = True

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "temperature-status.py"
SPEC = importlib.util.spec_from_file_location("temperature_status", SCRIPT_PATH)
ts = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ts)


class TestTemperatureStatus(unittest.TestCase):
    def _tree(self, tmp, files):
        base = Path(tmp)
        for rel, content in files.items():
            p = base / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
        return base

    def test_k10temp_tctl_preferred(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            hw = self._tree(tmpdir, {
                "hwmon0/name": "k10temp",
                "hwmon0/temp1_label": "Tctl",
                "hwmon0/temp1_input": "45000",
                "hwmon0/temp2_label": "Tccd1",
                "hwmon0/temp2_input": "43000",
            })
            res = ts.scan_hwmon(hw)
            self.assertEqual(res, (45.0, "k10temp/Tctl"))

    def test_k10temp_first_input_fallback(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            hw = self._tree(tmpdir, {"hwmon3/name": "k10temp",
                                     "hwmon3/temp2_input": "51250"})
            res = ts.scan_hwmon(hw)
            self.assertEqual(res, (51.25, "k10temp"))

    def test_ignores_other_drivers(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            hw = self._tree(tmpdir, {"hwmon0/name": "acpitz",
                                     "hwmon0/temp1_input": "30000"})
            self.assertIsNone(ts.scan_hwmon(hw))

    def test_thermal_cpu_zone(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            th = self._tree(tmpdir, {"thermal_zone0/type": "x86_pkg_temp",
                                     "thermal_zone0/temp": "60000"})
            res = ts.scan_thermal(th)
            self.assertEqual(res, (60.0, "x86_pkg_temp"))

    def test_thermal_first_readable_fallback(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            th = self._tree(tmpdir, {"thermal_zone5/type": "acpitz",
                                     "thermal_zone5/temp": "41.5"})
            res = ts.scan_thermal(th)
            self.assertEqual(res, (41.5, "acpitz"))

    def test_no_sensor(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            empty = Path(tmpdir)
            self.assertIsNone(ts.scan_hwmon(empty / "hw"))
            self.assertIsNone(ts.scan_thermal(empty / "th"))
            with unittest.mock.patch.object(ts, "HWMON_BASE", empty / "hw"), \
                 unittest.mock.patch.object(ts, "THERMAL_BASE", empty / "th"):
                res = ts.read_temperature()
                self.assertFalse(res["ok"])


if __name__ == "__main__":
    unittest.main()
