# Migration from v1

The original image used Bazzite GNOME as a base, installed Hyprland on top,
removed a large part of GNOME, copied personal dotfiles into `/etc/skel`,
cloned shell components during the OS build, and overrode low-level
container/OSTree settings.

v2 changes the ownership model.

## Base

Old:

```text
ghcr.io/ublue-os/bazzite-gnome:stable
```

New:

```text
ghcr.io/wayblueorg/hyprland:latest
```

Wayblue owns Hyprland, Waybar, the XDG portal, Hypridle/Hyprlock, launcher
plumbing, PipeWire/WirePlumber, NetworkManager tooling and the normal Wayland
desktop base.

## Dotfiles

User configuration is no longer copied to `/etc/skel`.

Keep your actual Hyprland, Waybar, SwayNC, Ghostty and shell configuration in
a separate dotfiles repository. This is especially useful because Wayblue can
start `~/.config/hypr/hyprland.lua` directly.

## Power

v2 does not add TLP. Wayblue already uses `tuned-ppd`, so there should be one
power-policy owner.

`thinkfan` is configured and enabled for the target ThinkPad T14 Gen 1 AMD.
The image installs the validated curve in `/etc/thinkfan.conf` and enables
`thinkpad_acpi` fan control through `/etc/modprobe.d/99-thinkfan.conf`.
Do not deploy this hardware-specific configuration unchanged to other models.

Battery charge protection is independent from TuneD. A oneshot service writes
the validated 75/80 thresholds through the kernel's `thinkpad_acpi` sysfs
interface at boot. TuneD remains the only owner of runtime power policy.

## sched_ext

v2 uses Fedora's packaged sched_ext schedulers instead of replacing the
kernel merely for scheduler support:

- `scx_layered`
- `scx_rusty`

## Removed v1 behavior

- No GNOME teardown
- No custom `/etc/containers/storage.conf`
- No custom ComposeFS switch
- No Powerlevel10k `git clone` during the image build
- No large binaries vendored into `$HOME`
- No `/etc/skel` as a dotfiles synchronization mechanism

## Recommended migration

1. Keep a known-good current deployment available for rollback.
2. Back up `$HOME/.config`, `$HOME/.local` and relevant `/etc` changes.
3. Rebase to the unsigned v2 image and reboot.
4. Confirm the Wayblue Hyprland session works with its defaults.
5. Rebase to the signed image and reboot.
6. Apply your current dotfiles separately.
7. Confirm Thinkfan detects `k10temp` and `/proc/acpi/ibm/fan`, then verify its
   service status and temperature transitions.
