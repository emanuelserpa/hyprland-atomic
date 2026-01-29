FROM ghcr.io/ublue-os/main-base:latest

# Enable COPRs
RUN dnf copr enable -y solopasha/hyprland && \
    dnf copr enable -y scottames/ghostty && \
    printf "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/\$releasever/\nenabled=1\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nmetadata_expire=120m\n" > /etc/yum.repos.d/insync.repo && \
    rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key

# Install packages
RUN rpm-ostree install \
    gdm \
    gnome-shell \
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
    steam \
    lutris \
    && rpm-ostree cleanup -m

# Enable GDM
RUN systemctl enable gdm

# Copy system files
COPY files/system /

# Run build script
COPY files/scripts/build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh && rm /tmp/build.sh
