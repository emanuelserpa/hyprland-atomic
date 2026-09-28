# Instalação limpa da sessão labwc + quickshell

Base: Arch/CachyOS com `sudo`, `git`, `yadm` e chave SSH no GitHub.
Testado em CachyOS (repositórios `*-v3`); no Arch puro, `quickshell`
pode precisar do AUR.

## 1. Dotfiles (traz o quickshell junto)

```bash
yadm clone git@github.com:emanuelserpa/dotfiles.git
```

O `.config/yadm/bootstrap` clona `emanuelserpa/quickshell.git` em
`~/.config/quickshell` automaticamente.

## 2. Pacotes

```bash
sudo pacman -S --needed \
  labwc uwsm quickshell \
  kanshi wlr-randr swayidle swaylock wlopm \
  fcitx5 fcitx5-qt hyprlock wtype \
  waypaper easyeffects kitty \
  tlp networkmanager network-manager-applet \
  wl-clipboard grim slurp swappy brightnessctl upower \
  noto-fonts ttf-noto-nerd bibata-cursor-theme \
  python-requests python-pillow \
  nmcli bluetoothctl blueberry \
  htop polkit hyprpolkitagent
```

Per-feature (só se usar): `kdeconnect`, `cups`, Flatpaks, Steam.
Não instale `power-profiles-daemon` (conflita com o TLP) nem
`nm-applet` como tray (desativado de propósito; segredos via diálogo).

## 3. Correções em `/etc` (não versionadas — reaplicar à mão)

Leitor Synaptics `06cb:00bd` trava sem isto:

```bash
# /etc/tlp.conf
USB_DENYLIST="06cb:00bd"
sudo tlp usb
```

```bash
# /etc/udev/rules.d/99-fingerprint.rules
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="06cb", ATTRS{idProduct}=="00bd", ATTR{power/control}="on"
sudo udevadm control --reload && sudo udevadm trigger
```

```bash
# /usr/lib/systemd/system-sleep/fprintd-reset  (chmod +x)
#!/bin/sh
[ "$1" = "post" ] && systemctl restart fprintd
```

## 4. Serviços do usuário

```bash
systemctl --user enable quickshell.service
systemctl --user daemon-reload
```

`hypridle` só sobe no Hyprland (drop-in já versionado);
`quickshell` sobe pelas duas sessões via `graphical-session.target`.

## 5. Primeiro login

1. No greeter, escolha **labwc (uwsm-managed)** (nunca o `labwc` puro).
2. Valide o shell:
   ```bash
   cd ~/.config/quickshell && ./scripts/validate.sh
   ```
3. Manual, uma vez: papel de parede no waypaper, senha do Wi-Fi no
   popup da barra, digitais com `fprintd-enroll $USER`.

## 6. Atalhos que precisam existir (já versionados em `rc.xml`)

`Win+Return` terminal, `Win+D/C/A/E/K/Tab` spotlight,
`Win+1..0` desktops, `Win+L` lock (hyprlock), `Win+Tab` janelas.
Detalhes em `docs/system-setup.md`.
