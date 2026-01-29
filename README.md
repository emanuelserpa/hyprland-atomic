# hyprland-atomic &nbsp; [![bluebuild build badge](https://github.com/emanuelserpa/hyprland-atomic/actions/workflows/build.yml/badge.svg)](https://github.com/emanuelserpa/hyprland-atomic/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

After setup, it is recommended you update this README to describe your custom image.

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

### Migrating from Silverblue or Bazzite

To migrate from an existing Fedora Silverblue or Bazzite installation to this image, run the following command:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/emanuelserpa/hyprland-atomic:latest
```

Then reboot to complete the installation:

```bash
systemctl reboot
```



## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/emanuelserpa/hyprland-atomic
```
