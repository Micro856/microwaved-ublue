# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/kinoite-main:latest

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

# Setup Copr
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    for copr in \
        gmaglione/podman-bootc \
        ublue-os/staging \
        ublue-os/packages; \
    do \
    dnf5 -y install dnf5-plugins && \
    dnf5 -y copr enable $copr; \
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null


# do rest of weird stuff
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf -y install --skip-unavailable love google-noto-fonts-all glow gum zsh ksystemlog gcc bootc borgbackup firacode-nerd-fonts jetbrains-mono-fonts-all nerdfontssymbolsonly-nerd-fonts plasma-wallpapers-dynamic make adobe-source-code pro-fonts bcc code dbus-x11 docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin flatpak-builder genisoimage google-droid-sans-mono-fonts google-go-mono-fonts ibm-plex-mono-fonts libvirt libvirt-nss mozilla-fira-mono-fonts osbuild-selinux p7zip p7zip-plugins podman-bootc podman-compose podman-machine podman-tui podmansh powerline-fonts qemu qemu-char-spice qemu-device-display-virtio-gpu qemu-device-display-virtio-vga qemu-device-usb-redirect qemu-img qemu-system-x86-core qemu-user-binfmt qemu-user-static ublue-os-libvirt-workarounds virt-manager virt-v2v distrobox podman ublue-bling ublue-brew uupd ublue-fastfetch ublue-branding-logos ublue-motd ublue-polkit-rules ublue-setup-services waydroid && \
    dnf -y remove fcitx5 kdedebugsettings kate kate-krunner-plugin kate-plugins fedora-bookmarks fedora-chromium-config fedora-chromium-config-kde firefox firefox-langpacks firewall-config kcharselect krfb krfb-libs plasma-discover-kns plasma-welcome-fedora podman-docker krdp kwrite ark ark-libs htop nvtop && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable brew-setup.service && \
    systemctl enable brew-upgrade.timer && \
    systemctl enable brew-update.timer && \
    systemctl enable ublue-system-setup.service && \
    systemctl --global enable ublue-user-setup.service && \
    systemctl --global enable podman-auto-update.timer && \
    systemctl enable check-sb-key.service && \
    systemctl enable uupd.timer && \
    systemctl disable rpm-ostreed-automatic.timer && \
    systemctl disable flatpak-system-update.timer && \
    dnf5 -y copr disable ublue-os/staging && \
    dnf5 -y copr disable ublue-os/packages && \
    dnf5 -y copr disable gmaglione/podman-bootc && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
