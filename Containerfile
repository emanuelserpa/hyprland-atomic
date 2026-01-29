FROM ghcr.io/ublue-os/bazzite-gnome:stable

# Enable COPRs
RUN dnf copr enable -y sdegler/hyprland && \
    dnf copr enable -y scottames/ghostty && \
    printf "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/\$releasever/\nenabled=1\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nmetadata_expire=120m\n" > /etc/yum.repos.d/insync.repo && \
    rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key

# Install packages
RUN rpm-ostree install \
    hyprland \
    hyprpaper \
    hypridle \
    hyprlock \
    xdg-desktop-portal-hyprland \
    waybar \
    wofi \
    mako \
    grimblast \
    copyq \
    pamixer \
    brightnessctl \
    wob \
    mate-polkit \
    neovim \
    zsh \
    mpv \
    yt-dlp \
    htop \
    glances \
    screen \
    waypaper \
    swww \
    foot \
    network-manager-applet \
    insync \
    google-noto-sans-fonts \
    playerctl \
    python3-requests \
    fontawesome-fonts-all \
    && rpm-ostree cleanup -m

# Remove packages
RUN packages_to_remove=( \
    baobab \
    cheese \
    eog \
    evince \
    file-roller \
    gnome-text-editor \
    simple-scan \
    gnome-user-docs \
    gnome-bluetooth \
    gnome-color-manager \
    gnome-calculator \
    gnome-calendar \
    gnome-characters \
    gnome-clocks \
    gnome-contacts \
    gnome-maps \
    gnome-weather \
    totem \
    loupe \
    snapshot \
    ) && \
    installed_packages=$(rpm -qa --qf "%{NAME}\n" | grep -E "^($(IFS=\|; echo "${packages_to_remove[*]}"))$") && \
    if [ -n "$installed_packages" ]; then \
    echo "Removing: $installed_packages"; \
    rpm-ostree override remove $installed_packages; \
    else \
    echo "No packages to remove."; \
    fi && \
    rpm-ostree cleanup -m

# Copy system files
COPY files/system /

# Run build script
COPY files/scripts/build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh && rm /tmp/build.sh
