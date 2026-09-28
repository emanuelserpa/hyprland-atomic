import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "wallpaper-action.py"
SPEC = importlib.util.spec_from_file_location("wallpaper_action", SCRIPT)
wallpaper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(wallpaper)


class TestWallpaperAction(unittest.TestCase):
    def test_apply_preserves_selected_gallery_folder(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            gallery = base / "gallery"
            gallery.mkdir()
            image = base / "elsewhere" / "image.png"
            image.parent.mkdir()
            image.write_bytes(b"image")
            state = base / "state" / "wallpaper.json"
            state.parent.mkdir()
            state.write_text(json.dumps({"folder": str(gallery)}))

            with patch.object(wallpaper, "STATE_DIR", state.parent), \
                 patch.object(wallpaper, "WALLPAPER_STATE", state), \
                 patch.object(wallpaper, "CURRENT_WALLPAPER", base / "current_wallpaper"), \
                 patch.object(wallpaper.shutil, "which", return_value="/usr/bin/awww"), \
                 patch.object(wallpaper.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)):
                ok, error = wallpaper.apply_wallpaper(image)

            self.assertTrue(ok, error)
            self.assertEqual(json.loads(state.read_text()), {
                "wallpaper": str(image), "folder": str(gallery),
            })
            self.assertEqual((base / "current_wallpaper").read_bytes(), b"image")


if __name__ == "__main__":
    unittest.main()
