# Instalação limpa da sessão Hyprland + quickshell

Base: Arch/CachyOS com `sudo`, `git`, `yadm` e chave SSH no GitHub.
Sessão diária original; o guia do labwc está em `docs/labwc-install.md`.

## 1. Dotfiles (traz o quickshell junto)

```bash
yadm clone git@github.com:emanuelserpa/dotfiles.git
```

O `.config/yadm/bootstrap` clona `emanuelserpa/quickshell.git` em
`~/.config/quickshell` automaticamente.

## 2. Pacotes

```bash
sudo pacman -S --needed \
  hyprland hypridle hyprlock hyprpolkitagent hyprsunset \
  xdg-desktop-portal-hyprland hyprshutdown \
  uwsm qt6ct nwg-displays \
  kitty waypaper easyeffects \
  tlp networkmanager \
  wl-clipboard grim slurp swappy brightnessctl upower \
  noto-fonts ttf-noto-nerd bibata-cursor-theme \
  python-requests python-pillow \
  nmcli bluetoothctl blueberry \
  htop polkit fcitx5 fcitx5-qt
```

Base compartilhada com o labwc (kanshi, swayidle, swaylock, wtype,
`nwg-displays` gera `hypr/monitors.conf`): ver `docs/labwc-install.md §2`.
Não instale `power-profiles-daemon` (conflita com o TLP) nem `swaync`
(nativas do shell).

## 3. Correções em `/etc` (não versionadas — reaplicar à mão)

As mesmas do labwc (`docs/labwc-install.md §3`): `USB_DENYLIST` do TLP,
regra udev e hook `fprintd-reset` para o Synaptics `06cb:00bd`.

## 4. Serviços do usuário

```bash
systemctl --user enable quickshell.service hypridle.service
systemctl --user daemon-reload
```

## 5. Primeiro login

1. No greeter, escolha **Hyprland (uwsm-managed)**.
2. Valide o shell:
   ```bash
   cd ~/.config/quickshell && ./scripts/validate.sh
   ```
3. Manual, uma vez: papel de parede no waypaper, monitores no
   nwg-displays, senha do Wi-Fi no popup da barra, digitais com
   `fprintd-enroll $USER`.

## 6. Atalhos (versão curta; completa em `docs/system-setup.md`)

`Win+Return` terminal, `Win+D/C/A/E/K/Tab` spotlight,
`Win+L` lock, `Win+Shift+C` QR da tela, `Print` screenshots.
