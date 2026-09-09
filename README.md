# Noctalia SDDM Theme for Parch Linux 

Improved version of [mahaveergurjar noctalia sddm theme](https://github.com/mahaveergurjar/sddm/tree/noctalia)

![screenshot](https://raw.githubusercontent.com/parchlinux/sddm-noctalia-parch/refs/heads/main/images/screenshot.png)

## Features
- Monochrome Theme
- customizable theme through editing colors in Main.qml
- MultiUser support
- Google Sans Font
## Manual Installation

### 1. Clone the repository

```sh
git clone https://github.com/parchlinux/sddm-noctalia-parch
```

### 2. Install the theme

Move the theme folder to the SDDM themes directory:

```sh
sudo cp -r sddm-noctalia-parch/ /usr/share/sddm/themes/
```

### 4. Restart SDDM

To apply the changes, restart the display manager:

```sh
sudo systemctl restart sddm
```

## Installation With PKGBUILD or Parch Repo

You can install directly from Parch world Repo
```sh
sudo pacman -S sddm-noctalia-parch
```

If you are using another distro (arch or arch based) you can use PKGBUILD

### 1. Install ttf-google-sans

```sh
git clone https://aur.archlinux.org/packages/ttf-google-sans.git && cd ttf-google-sans
makepkg -scfi
```

or with AUR helpers 

```sh
paru -S ttf-google-sans
```

### 2. Build and Install

```sh
git clone https://github.com/parchlinux/sddm-noctalia-parch && cd sddm-noctalia-parch
makepkg -scfi
```

## SDDM Configuration

Apply Theme on sddm config :

```sh
sudo nano /etc/sddm.conf.d/theme.conf

```
Add or modify the `[Theme]` section:

```ini
[Theme]
Current=noctalia-parch
```

## Cusomization

You can easily change color palette With edditing Main.qml 

```qml
readonly property color mPrimary: "#d6d6d6"
readonly property color mOnPrimary: "#151515"
readonly property color mSurface: "#151515"
readonly property color mSurfaceVariant: "#212121"
readonly property color mOnSurface: "#eeeeee"
readonly property color mOnSurfaceVariant: "#a0a0a0"
readonly property color mError: "#b8b8b8"
readonly property color mOutline:"#3e3e3e"
```






