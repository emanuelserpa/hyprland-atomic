FROM ghcr.io/ublue-os/bazzite-gnome:stable

# Enable COPRs
RUN dnf copr enable -y solopasha/hyprland && \
    dnf copr enable -y scottames/ghostty && \
    dnf copr enable -y che/nerd-fonts && \
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
    python3-pip \
    google-noto-sans-fonts \
    google-noto-sans-cjk-fonts \
    nerd-fonts \
    playerctl \
    python3-requests \
    fontawesome-fonts-all \
    && pip install maestral \
    && rpm-ostree cleanup -m

# Remove packages
RUN rpm-ostree override remove \
    firefox \
    firefox-langpacks \
    gnome-calculator \
    gnome-calendar \
    gnome-characters \
    gnome-clocks \
    gnome-contacts \
    gnome-font-viewer \
    gnome-logs \
    gnome-maps \
    gnome-weather \
    gnome-disk-utility \
    gnome-system-monitor \
    gnome-text-editor \
    baobab \
    totem \
    loupe \
    snapshot \
    simple-scan \
    evince \
    yelp \
    gnome-tour \
    gnome-software && rpm-ostree cleanup -m

# Copy system files
COPY files/system /

# Run build script
COPY files/scripts/build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh && rm /tmp/build.sh
