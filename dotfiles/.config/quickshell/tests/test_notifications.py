#!/usr/bin/env python3
import html
import re
import sys
sys.dont_write_bytecode = True
import unittest

def format_text(s):
    if not s:
        return ""
    s = str(s)
    s = re.sub(r'<br\s*/?>', '\n', s, flags=re.IGNORECASE)
    s = re.sub(r'<[^>]+>', '', s)
    s = s.replace('&quot;', '"')
    s = s.replace('&apos;', "'")
    s = s.replace('&#39;', "'")
    s = s.replace('&#x27;', "'")
    s = s.replace('&lt;', '<')
    s = s.replace('&gt;', '>')
    s = s.replace('&nbsp;', ' ')
    s = s.replace('&amp;', '&')
    s = re.sub(r'&#(\d+);', lambda m: chr(int(m.group(1))), s)
    s = re.sub(r'&#x([0-9a-fA-F]+);', lambda m: chr(int(m.group(1), 16)), s)
    return s.strip()

def is_placeholder_label(s):
    t = str(s or "").strip().lower()
    if len(t) == 0:
        return True
    placeholders = {
        "notificação", "notificacao", "notificações", "notificacoes",
        "notification", "notifications", "new notification", "nova notificação",
        "unknown", "desconhecido", "ação", "acao", "action", "actions",
        "null", "undefined", "none", "nenhum", "empty", "vazio"
    }
    return t in placeholders

def has_real_image(image, app_icon=""):
    img = str(image or "").strip()
    if not img:
        return False
    if img.startswith("image://icon/"):
        return False
    app_icon = str(app_icon or "").strip()
    if app_icon and img == app_icon:
        return False
    return img.startswith("/") or img.startswith("file://")

def has_useful_action(actions):
    if not actions:
        return False
    for a in actions:
        text = str(a.get("text") or a.get("label") or "").strip()
        if text and not is_placeholder_label(text):
            return True
    return False

def notification_has_useful_content(summary="", body="", image="", app_icon="", actions=None, app_name=""):
    s = format_text(summary)
    b = format_text(body)
    summary_ok = bool(s and not is_placeholder_label(s))
    body_ok = bool(b and not is_placeholder_label(b))
    if summary_ok or body_ok:
        return True
    if has_real_image(image, app_icon):
        return True
    return has_useful_action(actions)

class TestNotificationHardening(unittest.TestCase):
    def test_format_text_html_entities(self):
        self.assertEqual(format_text("&quot;Hello&quot; &amp; &lt;world&gt;"), '"Hello" & <world>')
        self.assertEqual(format_text("It&#39;s a &#x27;test&#x27;"), "It's a 'test'")
        self.assertEqual(format_text("Line1<br>Line2<br/>Line3"), "Line1\nLine2\nLine3")
        self.assertEqual(format_text("<b>Bold</b> and <i>italic</i>"), "Bold and italic")
        self.assertEqual(format_text("   "), "")

    def test_is_placeholder_label(self):
        self.assertTrue(is_placeholder_label(""))
        self.assertTrue(is_placeholder_label("   "))
        self.assertTrue(is_placeholder_label("notificação"))
        self.assertTrue(is_placeholder_label("NOTIFICACAO"))
        self.assertTrue(is_placeholder_label("Notification"))
        self.assertTrue(is_placeholder_label("Nova Notificação"))
        self.assertTrue(is_placeholder_label("unknown"))
        self.assertTrue(is_placeholder_label("null"))
        self.assertTrue(is_placeholder_label("ação"))
        self.assertFalse(is_placeholder_label("Spotify"))
        self.assertFalse(is_placeholder_label("Maria Silva"))
        self.assertFalse(is_placeholder_label("Download concluído"))

    def test_discard_empty_notification_with_app_name(self):
        # Even if appName is Spotify or Zen, if summary and body are empty, it must be discarded!
        self.assertFalse(
            notification_has_useful_content(summary="", body="", app_name="Spotify")
        )
        self.assertFalse(
            notification_has_useful_content(summary="   ", body="\n\n", app_name="Zen Browser")
        )
        self.assertFalse(
            notification_has_useful_content(summary="Notificação", body="", app_name="Spotify")
        )

    def test_accept_valid_summary_only(self):
        self.assertTrue(
            notification_has_useful_content(summary="Reunião às 16h", body="", app_name="Calendar")
        )

    def test_accept_valid_body_only(self):
        self.assertTrue(
            notification_has_useful_content(summary="", body="Build concluído em 3.2s", app_name="Terminal")
        )

    def test_accept_both_summary_and_body(self):
        self.assertTrue(
            notification_has_useful_content(
                summary="Telegram",
                body="Nova mensagem recebida",
                app_name="Telegram"
            )
        )

    def test_accept_real_image_attachment(self):
        self.assertTrue(
            notification_has_useful_content(
                summary="",
                body="",
                image="/home/user/Pictures/screenshot.png",
                app_name="Flameshot"
            )
        )

    def test_reject_app_icon_as_image(self):
        self.assertFalse(
            notification_has_useful_content(
                summary="",
                body="",
                image="image://icon/firefox",
                app_name="Firefox"
            )
        )
        self.assertFalse(
            notification_has_useful_content(
                summary="",
                body="",
                image="firefox",
                app_icon="firefox",
                app_name="Firefox"
            )
        )

    def test_accept_useful_action(self):
        self.assertTrue(
            notification_has_useful_content(
                summary="",
                body="",
                actions=[{"text": "Aceitar"}, {"text": "Recusar"}],
                app_name="Pairing"
            )
        )

    def test_reject_placeholder_action(self):
        self.assertFalse(
            notification_has_useful_content(
                summary="",
                body="",
                actions=[{"text": "Ação"}],
                app_name="Prompt"
            )
        )

    def test_notification_pill_color_resolution(self):
        def resolve_color(count, dnd, has_critical):
            if has_critical:
                return "red"
            if dnd:
                return "grey"
            if count > 0:
                return "blue"
            return "offWhite"

        # 0 notifications, normal -> offWhite
        self.assertEqual(resolve_color(0, False, False), "offWhite")
        # 0 notifications, DND -> grey
        self.assertEqual(resolve_color(0, True, False), "grey")
        # Standard notification -> blue (not red!)
        self.assertEqual(resolve_color(1, False, False), "blue")
        self.assertEqual(resolve_color(5, False, False), "blue")
        # Standard notification under DND -> grey
        self.assertEqual(resolve_color(3, True, False), "grey")
        # Critical notification -> red (even with DND!)
        self.assertEqual(resolve_color(1, False, True), "red")
        self.assertEqual(resolve_color(1, True, True), "red")

    def test_battery_pill_color_resolution(self):
        def resolve_color(ready, charging, plugged, pct):
            if not ready:
                return "offWhite"
            if charging:
                return "green"
            if not plugged and pct <= 15:
                return "red"
            if not plugged and pct <= 30:
                return "yellow"
            return "offWhite"

        # Not ready -> offWhite
        self.assertEqual(resolve_color(False, False, False, 10), "offWhite")
        # Normal discharge -> offWhite
        self.assertEqual(resolve_color(True, False, False, 80), "offWhite")
        self.assertEqual(resolve_color(True, False, False, 31), "offWhite")
        # Warning discharge <= 30% -> yellow
        self.assertEqual(resolve_color(True, False, False, 30), "yellow")
        self.assertEqual(resolve_color(True, False, False, 16), "yellow")
        # Critical discharge <= 15% -> red
        self.assertEqual(resolve_color(True, False, False, 15), "red")
        self.assertEqual(resolve_color(True, False, False, 5), "red")
        # Charging -> green (even if low percentage!)
        self.assertEqual(resolve_color(True, True, True, 14), "green")
        self.assertEqual(resolve_color(True, True, True, 85), "green")
        # Plugged at 80% (threshold reached, not charging) -> offWhite
        self.assertEqual(resolve_color(True, False, True, 80), "offWhite")

if __name__ == "__main__":
    unittest.main()
