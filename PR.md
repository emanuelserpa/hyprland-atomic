# Suggested pull request

## Title

Refactor image v2 on top of Wayblue Hyprland

## Body

This refactors `hyprland-atomic` around a much smaller ownership boundary.

### Changes

- replace Bazzite GNOME base with Wayblue Hyprland
- replace imperative Containerfile/rpm-ostree layering with a BlueBuild recipe
- remove the GNOME teardown list
- stop baking user dotfiles into `/etc/skel`
- stop overriding Podman storage and ComposeFS settings
- stop cloning Powerlevel10k during the OS build
- add SwayNotificationCenter, Fedora sched_ext schedulers, and the validated
  ThinkPad T14 Gen 1 AMD Thinkfan configuration
- keep Ghostty and the small workstation tool layer
- keep signing through BlueBuild
- document unsigned -> signed rebase flow
- add migration notes for the existing v1 installation

### Deliberate choices

- no TLP: Wayblue already provides `tuned-ppd`
- Thinkfan is explicitly hardware-specific and enabled only because this image
  targets the validated ThinkPad T14 Gen 1 AMD
- no CachyOS kernel: Fedora's sched_ext packages are sufficient to start with
- no large user binaries vendored into the image

### Follow-up

Move the current live Hyprland/Waybar/SwayNC/Zsh configuration into a
dedicated dotfiles repository.
